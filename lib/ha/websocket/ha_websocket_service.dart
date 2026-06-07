import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_connection.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/repository/entity_state_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Thrown when an HA `call_service` returns `success: false`.
class HaServiceCallException implements Exception {
  final String message;
  HaServiceCallException(this.message);
  @override
  String toString() => 'HaServiceCallException: $message';
}

/// Owns the live HA WebSocket connection: authentication, the entity
/// subscription, service calls, and exponential-backoff reconnection.
class HaWebSocketService {
  final AuthServiceConnection _connection;
  final EntityStateRepository repository;

  HaWebSocketService({
    required AuthServiceConnection connection,
    required this.repository,
  }) : _connection = connection;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  int _msgId = 1;
  bool _closedByUser = false;
  int _backoffSeconds = 1;
  Timer? _reconnectTimer;

  // Completers keyed by message id awaiting a `result` frame.
  final Map<int, Completer<dynamic>> _pending = {};

  // Entity ids with an in-flight service call (for the pending-spinner UI).
  final Set<String> _pendingEntities = {};
  final _pendingController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get pendingEntities => _pendingController.stream;
  Set<String> get currentPending => Set.unmodifiable(_pendingEntities);

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get status => _statusController.stream;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _status;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> connect() async {
    _closedByUser = false;
    _setStatus(_backoffSeconds == 1
        ? ConnectionStatus.connecting
        : ConnectionStatus.reconnecting);
    try {
      final token = await _connection.getAccessToken();
      final uri = _connection.websocketUri;
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;

      final authed = Completer<bool>();
      _socketSub = channel.stream.listen(
        (raw) => _onMessage(raw, authed, token),
        onError: (e) => _onSocketClosed(),
        onDone: _onSocketClosed,
        cancelOnError: false,
      );

      final ok = await authed.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (!ok) {
        await _teardownSocket();
        _scheduleReconnect();
        return;
      }

      _backoffSeconds = 1; // reset backoff on a clean connect
      _setStatus(ConnectionStatus.connected);
      await _subscribe();
    } catch (_) {
      await _teardownSocket();
      _scheduleReconnect();
    }
  }

  Future<void> close() async {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    await _teardownSocket();
    _setStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    close();
    _statusController.close();
    _pendingController.close();
  }

  // ── Message handling ────────────────────────────────────────────────────────

  void _onMessage(dynamic raw, Completer<bool> authed, String token) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (msg['type']) {
      case 'auth_required':
        _send({'type': 'auth', 'access_token': token});
        break;
      case 'auth_ok':
        if (!authed.isCompleted) authed.complete(true);
        break;
      case 'auth_invalid':
        if (!authed.isCompleted) authed.complete(false);
        _connection.onAuthInvalid();
        break;
      case 'result':
        _handleResult(msg);
        break;
      case 'event':
        _handleEvent(msg);
        break;
    }
  }

  void _handleResult(Map<String, dynamic> msg) {
    final id = msg['id'] as int?;
    if (id == null) return;
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;
    if (msg['success'] == true) {
      completer.complete(msg['result']);
    } else {
      final err = msg['error'];
      final message = err is Map ? (err['message']?.toString() ?? 'error') : 'error';
      completer.completeError(HaServiceCallException(message));
    }
  }

  void _handleEvent(Map<String, dynamic> msg) {
    final event = msg['event'];
    if (event is! Map) return;

    // subscribe_entities compressed format: a=added, c=changed, r=removed
    if (event.containsKey('a')) {
      final added = (event['a'] as Map).cast<String, dynamic>();
      added.forEach((entityId, data) {
        final d = (data as Map).cast<String, dynamic>();
        repository.put(EntityState(
          entityId: entityId,
          state: d['s']?.toString() ?? 'unknown',
          attributes:
              (d['a'] as Map?)?.cast<String, dynamic>() ?? const {},
          lastUpdated: _epoch(d['lu']),
        ));
      });
    }
    if (event.containsKey('c')) {
      final changed = (event['c'] as Map).cast<String, dynamic>();
      changed.forEach((entityId, data) {
        final d = (data as Map).cast<String, dynamic>();
        final plus = (d['+'] as Map?)?.cast<String, dynamic>();
        final minus = (d['-'] as Map?)?.cast<String, dynamic>();
        repository.applyDiff(
          entityId,
          state: plus?['s']?.toString(),
          changedAttributes:
              (plus?['a'] as Map?)?.cast<String, dynamic>(),
          removedAttributes:
              (minus?['a'] as List?)?.map((e) => e.toString()).toList(),
          lastUpdated: plus?['lu'] != null ? _epoch(plus!['lu']) : null,
        );
      });
    }

    // Fallback (subscribe_events state_changed) format.
    if (event['event_type'] == 'state_changed') {
      final data = (event['data'] as Map?)?.cast<String, dynamic>();
      final newState = data?['new_state'];
      if (newState is Map) {
        final entityId = newState['entity_id'] as String?;
        if (entityId != null && HaEntities.allowlist.contains(entityId)) {
          repository.put(
              EntityState.fromJson(newState.cast<String, dynamic>()));
        }
      }
    }
  }

  DateTime _epoch(dynamic v) {
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
    }
    return DateTime.now();
  }

  // ── Subscription ────────────────────────────────────────────────────────────

  Future<void> _subscribe() async {
    try {
      await _request({
        'type': 'subscribe_entities',
        'entity_ids': HaEntities.allowlist,
      });
    } catch (_) {
      // Fallback for HA < 2022.9 — subscribe to all state_changed and filter.
      await _request({
        'type': 'subscribe_events',
        'event_type': 'state_changed',
      });
    }
  }

  // ── Service calls ────────────────────────────────────────────────────────────

  /// Fetches the area registry via WebSocket, returning area_id → mdi icon.
  /// Areas with no icon set are omitted from the result.
  Future<Map<String, String>> fetchAreaIcons() async {
    final result = await _request({'type': 'config/area_registry/list'})
        .timeout(const Duration(seconds: 10));
    if (result is! List) return {};
    return {
      for (final area in result.cast<Map<String, dynamic>>())
        if (area['area_id'] is String && area['icon'] is String)
          area['area_id'] as String: area['icon'] as String,
    };
  }

  /// Sends a `call_service` command and completes when HA acknowledges it.
  /// Throws [HaServiceCallException] on failure.
  Future<void> callService({
    required String domain,
    required String service,
    Map<String, dynamic>? data,
    String? targetEntityId,
  }) async {
    final entityId = targetEntityId ?? data?['entity_id'] as String?;
    if (entityId != null) _markPending(entityId, true);

    final payload = <String, dynamic>{
      'type': 'call_service',
      'domain': domain,
      'service': service,
      if (data != null && data.isNotEmpty) 'service_data': data,
    };
    try {
      await _request(payload).timeout(const Duration(seconds: 5));
    } finally {
      if (entityId != null) _markPending(entityId, false);
    }
  }

  void _markPending(String entityId, bool pending) {
    if (pending) {
      _pendingEntities.add(entityId);
    } else {
      _pendingEntities.remove(entityId);
    }
    if (!_pendingController.isClosed) {
      _pendingController.add(Set.unmodifiable(_pendingEntities));
    }
  }

  /// Sends a command with an auto-incrementing id and awaits its `result`.
  Future<dynamic> _request(Map<String, dynamic> payload) {
    final id = _msgId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _send({...payload, 'id': id});
    return completer.future;
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(payload));
  }

  // ── Reconnection ────────────────────────────────────────────────────────────

  void _onSocketClosed() {
    if (_closedByUser) return;
    _failPending();
    _scheduleReconnect();
  }

  void _failPending() {
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(HaServiceCallException('connection lost'));
      }
    }
    _pending.clear();
    _pendingEntities.clear();
    if (!_pendingController.isClosed) _pendingController.add(const {});
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    _setStatus(ConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: _backoffSeconds);
    _reconnectTimer = Timer(delay, connect);
    _backoffSeconds = (_backoffSeconds * 2).clamp(1, 60);
    if (kDebugMode) {
      debugPrint('HA WS reconnecting in ${delay.inSeconds}s');
    }
  }

  Future<void> _teardownSocket() async {
    await _socketSub?.cancel();
    _socketSub = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
