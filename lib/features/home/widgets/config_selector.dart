import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// Full-width selector for `input_select.configuration`. This entity is the
/// top-level "concept" that drives scene and automation grouping across the app;
/// changing it tells HA which mode the household is in (e.g. Normal, Movie,
/// Away). Options come live from the entity's `options` attribute. Selection
/// derives from the shared [ModeSelector] treatment so it reads identically to
/// the room controls.
class ConfigSelector extends ConsumerWidget {
  const ConfigSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final entity =
        ref.watch(entityStateProvider(HaEntities.configSelect)).valueOrNull;

    if (entity == null) return const SizedBox.shrink();

    final current = entity.state;
    final options = entity.attrList<String>('options') ?? [current];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.offMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ModeSelector<String>(
            options: options,
            selected: current,
            labelOf: (o) => o,
            onSelect: (option) {
              if (option == current) return;
              ref.read(haServiceProvider).call(
                'input_select',
                'select_option',
                data: {
                  'entity_id': HaEntities.configSelect,
                  'option': option,
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
