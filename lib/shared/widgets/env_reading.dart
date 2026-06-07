import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Kinds of environment reading, each with its own formatting/colour rules.
enum EnvKind { temperature, humidity, illuminance, pm25 }

/// A compact icon + value chip for an environment reading. Reads the value from
/// either an entity's state or a named attribute. Renders nothing when the
/// source is unavailable (so rows reflow cleanly).
class EnvReading extends ConsumerWidget {
  final String entityId;
  final EnvKind kind;

  /// When set, read this attribute instead of the entity state (e.g. an AC's
  /// `current_temperature`).
  final String? attribute;

  const EnvReading({
    super.key,
    required this.entityId,
    required this.kind,
    this.attribute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    if (state == null || state.isUnavailable) return const SizedBox.shrink();

    final double? value = attribute != null
        ? state.attrDouble(attribute!)
        : double.tryParse(state.state);
    if (value == null) return const SizedBox.shrink();

    final (icon, text, color) = _format(value, tokens);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? tokens.offMuted),
          const SizedBox(width: 4),
          Text(text, style: tokens.sensorStyle.copyWith(color: color)),
        ],
      ),
    );
  }

  (IconData, String, Color?) _format(double value, AppTokens tokens) {
    switch (kind) {
      case EnvKind.temperature:
        return (MdiIcons.thermometer, '${value.toStringAsFixed(1)}°C', null);
      case EnvKind.humidity:
        return (MdiIcons.waterPercent, '${value.round()}%', null);
      case EnvKind.illuminance:
        return (MdiIcons.brightness5, '${value.round()} lx', null);
      case EnvKind.pm25:
        final color = value < 12
            ? const Color(0xFF66BB6A)
            : value <= 35
                ? const Color(0xFFFFB300)
                : const Color(0xFFEF5350);
        return (MdiIcons.airFilter, '${value.round()} µg/m³', color);
    }
  }
}
