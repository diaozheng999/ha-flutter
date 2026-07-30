import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// Effect selector for fixtures that advertise an `effect_list`. For a group the
/// list is HA's union across members, so selecting an effect applies to whichever
/// members support it.
///
/// Effects are mutually exclusive, so this uses the shared [ModeSelector] chip
/// treatment. Selecting the active effect again clears it back to `none` when the
/// fixture offers a no-effect option.
class LightEffectSelector extends ConsumerWidget {
  final String entityId;
  final List<String> effects;

  const LightEffectSelector({
    super.key,
    required this.entityId,
    required this.effects,
  });

  /// Effect names HA uses to mean "no effect".
  static const _noneNames = {'none', 'off'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (effects.isEmpty) return const SizedBox.shrink();
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    final current = state?.attrString('effect');
    final service = ref.read(haServiceProvider);

    return ModeSelector<String>(
      options: effects,
      selected: current,
      labelOf: (e) => e,
      onSelect: (effect) {
        // Re-tapping the active effect clears it, when the fixture has a way to
        // express "no effect".
        if (effect == current) {
          final none = effects.firstWhere(
            (e) => _noneNames.contains(e.toLowerCase()),
            orElse: () => '',
          );
          if (none.isEmpty) return;
          service.turnOn(entityId, {'effect': none});
          return;
        }
        service.turnOn(entityId, {'effect': effect});
      },
    );
  }
}
