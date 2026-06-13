import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_connection.dart';
import 'package:ha_flutter/ha/ha_rest_client.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/repository/entity_state_repository.dart';
import 'package:ha_flutter/ha/websocket/ha_websocket_service.dart';

/// Provides the live [AuthServiceConnection]. Must be overridden at the root
/// `ProviderScope` with the app's authenticated connection.
final haConnectionProvider = Provider<AuthServiceConnection>((ref) {
  throw UnimplementedError('haConnectionProvider must be overridden at root');
});

final entityRepositoryProvider = Provider<EntityStateRepository>((ref) {
  final repo = EntityStateRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final haRestClientProvider = Provider<HaRestClient>((ref) {
  return HaRestClient(ref.watch(haConnectionProvider));
});

final haWebSocketServiceProvider = Provider<HaWebSocketService>((ref) {
  final service = HaWebSocketService(
    connection: ref.watch(haConnectionProvider),
    repository: ref.watch(entityRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Area id → MDI icon string, fetched via WebSocket once the connection is up.
final areaIconsProvider = FutureProvider<Map<String, String>>((ref) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    return await ref.read(haWebSocketServiceProvider).fetchAreaIcons();
  } catch (_) {
    return {};
  }
});

/// Runs the REST state bootstrap for standalone (non-room) entities, then
/// opens the WebSocket. Room entities are bootstrapped separately by
/// [roomConfigsProvider] after the registry is fetched.
final dashboardInitProvider = FutureProvider<void>((ref) async {
  final ws = ref.watch(haWebSocketServiceProvider);
  final repo = ref.watch(entityRepositoryProvider);
  final rest = ref.watch(haRestClientProvider);

  ws.setBaseEntityIds(HaEntities.standaloneAllowlist);
  try {
    final states = await rest.fetchStates(HaEntities.standaloneAllowlist.toSet());
    repo.putAll(states);
  } catch (_) {
    // Bootstrap is best-effort; the WebSocket will deliver state regardless.
  }
  await ws.connect();
});

/// Per-entity live state. The single read surface for all widgets.
final entityStateProvider =
    StreamProvider.family<EntityState, String>((ref, entityId) {
  return ref.watch(entityRepositoryProvider).stream(entityId);
});

/// Convenience: the current [EntityState] (cached) for synchronous reads such
/// as aggregations, without a stream subscription.
EntityState entitySnapshot(Ref ref, String entityId) =>
    ref.read(entityRepositoryProvider).get(entityId);

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ref.watch(haWebSocketServiceProvider);
  // Prepend the current status so new subscribers never start in AsyncLoading,
  // which would cause the ConnectionChip to flash on every navigation.
  return () async* {
    yield service.currentStatus;
    yield* service.status;
  }();
});

final pendingEntitiesProvider = StreamProvider<Set<String>>((ref) {
  final service = ref.watch(haWebSocketServiceProvider);
  return service.pendingEntities;
});

/// True when a service call targeting [entityId] is in flight (drives spinners).
final entityPendingProvider = Provider.family<bool, String>((ref, entityId) {
  final pending = ref.watch(pendingEntitiesProvider).valueOrNull ?? const {};
  return pending.contains(entityId);
});

/// Thin call-service facade for widgets.
final haServiceProvider = Provider<HaService>((ref) {
  return HaService(ref.watch(haWebSocketServiceProvider));
});

/// Ergonomic wrapper around [HaWebSocketService.callService] with helpers for
/// the common domains used across the dashboard.
class HaService {
  final HaWebSocketService _ws;
  HaService(this._ws);

  Future<void> call(
    String domain,
    String service, {
    Map<String, dynamic>? data,
    String? target,
  }) =>
      _ws.callService(
        domain: domain,
        service: service,
        data: data,
        targetEntityId: target,
      );

  Future<void> toggle(String entityId) {
    final domain = entityId.split('.').first;
    return call(domain, 'toggle', data: {'entity_id': entityId});
  }

  Future<void> turnOn(String entityId, [Map<String, dynamic>? extra]) {
    final domain = entityId.split('.').first;
    return call(domain, 'turn_on', data: {'entity_id': entityId, ...?extra});
  }

  Future<void> turnOff(String entityId) {
    final domain = entityId.split('.').first;
    return call(domain, 'turn_off', data: {'entity_id': entityId});
  }
}
