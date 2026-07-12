import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/widgets/reading_pill.dart';

/// Kinds of environment reading, each with its own formatting/severity rules.
enum EnvKind { temperature, humidity, illuminance, pm25 }

/// A compact environment reading, rendered via the shared [ReadingPill]. Reads
/// the value from either an entity's state or a named attribute. Renders nothing
/// when the source is unavailable (so rows reflow cleanly). PM2.5 carries the
/// WHO severity mapping; the other kinds render neutral.
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
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    if (state == null || state.isUnavailable) return const SizedBox.shrink();

    final double? value = attribute != null
        ? state.attrDouble(attribute!)
        : double.tryParse(state.state);
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ReadingPill(spec: _spec(value)),
    );
  }

  ReadingSpec _spec(double value) => switch (kind) {
        EnvKind.temperature => ReadingSpec(
            icon: MdiIcons.thermometer,
            text: '${value.toStringAsFixed(1)}°C',
          ),
        EnvKind.humidity => ReadingSpec(
            icon: MdiIcons.waterPercent,
            text: '${value.round()}%',
          ),
        EnvKind.illuminance => ReadingSpec(
            icon: MdiIcons.brightness5,
            text: '${value.round()} lx',
          ),
        EnvKind.pm25 => ReadingSpec(
            icon: MdiIcons.airFilter,
            text: '${value.round()} µg/m³',
            value: value,
            severity: ReadingSpec.pm25,
          ),
      };
}
