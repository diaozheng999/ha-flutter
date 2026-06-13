// Declarative alert rules attached to rooms in ha_entities.dart. Rules cover
// semantics autodiscovery cannot infer (activity notices, consumable
// thresholds); standard safety/battery/problem sensors are discovered from the
// HA registries instead.

import 'package:ha_flutter/ha/models/entity_state.dart';

/// Severity tiers, highest first. Display order follows enum index.
enum RoomAlertSeverity { safety, activity, offline, maintenance, battery }

enum _AlertTrigger { stateIn, numericBelow }

/// A single entity-condition → alert mapping.
class AlertRule {
  final String entity;
  final _AlertTrigger _trigger;

  /// Matching states for [AlertRule.stateIn], compared lowercase.
  final List<String> states;

  /// Threshold for [AlertRule.numericBelow] (alert when state < threshold).
  final double threshold;

  final RoomAlertSeverity severity;

  /// Short display label, e.g. "Laundry done".
  final String label;

  /// Momentary rules (e.g. a doorbell ring) stay visible for 10 minutes after
  /// the triggering state change instead of clearing with the state.
  final bool momentary;

  const AlertRule.stateIn({
    required this.entity,
    required this.states,
    required this.severity,
    required this.label,
    this.momentary = false,
  })  : _trigger = _AlertTrigger.stateIn,
        threshold = 0;

  const AlertRule.numericBelow({
    required this.entity,
    required this.threshold,
    required this.severity,
    required this.label,
    this.momentary = false,
  })  : _trigger = _AlertTrigger.numericBelow,
        states = const [];

  bool matches(EntityState state) {
    if (state.isUnavailable || state.isUnknown) return false;
    switch (_trigger) {
      case _AlertTrigger.stateIn:
        return states.contains(state.state.toLowerCase());
      case _AlertTrigger.numericBelow:
        final v = double.tryParse(state.state);
        return v != null && v < threshold;
    }
  }
}
