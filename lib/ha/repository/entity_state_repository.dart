// Controllers are owned for the app lifetime and closed in dispose().
// ignore_for_file: close_sinks

import 'dart:async';

import 'package:ha_flutter/ha/models/entity_state.dart';

/// Holds the latest known [EntityState] for every subscribed entity and
/// broadcasts updates. This is the single read surface for the UI layer —
/// widgets reach it only through Riverpod providers, never directly.
class EntityStateRepository {
  final Map<String, EntityState> _cache = {};
  final Map<String, StreamController<EntityState>> _controllers = {};

  /// Current cached value for [entityId], or an `unknown` placeholder.
  EntityState get(String entityId) =>
      _cache[entityId] ?? EntityState.unknown(entityId);

  bool has(String entityId) => _cache.containsKey(entityId);

  /// A stream that immediately replays the last-known value (if any) and then
  /// emits every subsequent update for [entityId].
  Stream<EntityState> stream(String entityId) {
    final controller = _controllerFor(entityId);
    final current = _cache[entityId];
    if (current != null) {
      return Stream<EntityState>.value(current)
          .followedBy(controller.stream);
    }
    return controller.stream;
  }

  StreamController<EntityState> _controllerFor(String entityId) =>
      _controllers.putIfAbsent(
        entityId,
        () => StreamController<EntityState>.broadcast(),
      );

  /// Replaces the full state for an entity (REST bootstrap / full WS push).
  void put(EntityState state) {
    _cache[state.entityId] = state;
    _controllerFor(state.entityId).add(state);
  }

  /// Bulk replace, used by the REST bootstrap.
  void putAll(Iterable<EntityState> states) {
    for (final s in states) {
      put(s);
    }
  }

  /// Applies a partial diff to an existing entity, creating it if absent.
  void applyDiff(
    String entityId, {
    String? state,
    Map<String, dynamic>? changedAttributes,
    List<String>? removedAttributes,
    DateTime? lastUpdated,
  }) {
    final base = _cache[entityId] ?? EntityState.unknown(entityId);
    final next = base.applyDiff(
      state: state,
      changedAttributes: changedAttributes,
      removedAttributes: removedAttributes,
      lastUpdated: lastUpdated,
    );
    put(next);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}

extension<T> on Stream<T> {
  /// Emits this stream's events, then continues with [next].
  Stream<T> followedBy(Stream<T> next) async* {
    yield* this;
    yield* next;
  }
}
