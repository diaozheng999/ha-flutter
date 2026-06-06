/// Immutable snapshot of a Home Assistant entity's state.
///
/// Mirrors the shape HA delivers over both the REST `/api/states` endpoint and
/// the WebSocket `subscribe_entities` / `state_changed` feeds.
class EntityState {
  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final DateTime lastUpdated;

  const EntityState({
    required this.entityId,
    required this.state,
    required this.attributes,
    required this.lastUpdated,
  });

  /// Domain portion of the entity id, e.g. `light` for `light.kitchen`.
  String get domain => entityId.split('.').first;

  bool get isOn => state == 'on';
  bool get isUnavailable => state == 'unavailable';
  bool get isUnknown => state == 'unknown';

  /// Friendly name from attributes, falling back to the entity id.
  String get friendlyName =>
      attributes['friendly_name'] as String? ?? entityId;

  /// Reads an attribute as a [double] regardless of int/double/string source.
  double? attrDouble(String key) {
    final v = attributes[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? attrInt(String key) => attrDouble(key)?.round();

  String? attrString(String key) => attributes[key]?.toString();

  List<T>? attrList<T>(String key) {
    final v = attributes[key];
    if (v is List) return v.cast<T>();
    return null;
  }

  /// The `hs_color` attribute as a `[hue, saturation]` pair, if present.
  ({double hue, double saturation})? get hsColor {
    final raw = attributes['hs_color'];
    if (raw is List && raw.length == 2) {
      return (
        hue: (raw[0] as num).toDouble(),
        saturation: (raw[1] as num).toDouble(),
      );
    }
    return null;
  }

  factory EntityState.fromJson(Map<String, dynamic> json) {
    return EntityState(
      entityId: json['entity_id'] as String,
      state: json['state']?.toString() ?? 'unknown',
      attributes:
          (json['attributes'] as Map?)?.cast<String, dynamic>() ?? const {},
      lastUpdated: DateTime.tryParse(json['last_updated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Applies a partial diff (as delivered by `subscribe_entities`) on top of
  /// this state, returning a new [EntityState].
  EntityState applyDiff({
    String? state,
    Map<String, dynamic>? changedAttributes,
    List<String>? removedAttributes,
    DateTime? lastUpdated,
  }) {
    final attrs = Map<String, dynamic>.from(attributes);
    if (changedAttributes != null) attrs.addAll(changedAttributes);
    if (removedAttributes != null) {
      for (final k in removedAttributes) {
        attrs.remove(k);
      }
    }
    return EntityState(
      entityId: entityId,
      state: state ?? this.state,
      attributes: attrs,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// A placeholder used before any real state has been received.
  factory EntityState.unknown(String entityId) => EntityState(
        entityId: entityId,
        state: 'unknown',
        attributes: const {},
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Connection lifecycle state for the WebSocket layer.
enum ConnectionStatus { connecting, connected, reconnecting, disconnected }
