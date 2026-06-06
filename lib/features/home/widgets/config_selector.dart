import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Full-width selector for `input_select.configuration`. This entity is the
/// top-level "concept" that drives scene and automation grouping across the app;
/// changing it tells HA which mode the household is in (e.g. Normal, Movie,
/// Away). Options come live from the entity's `options` attribute.
class ConfigSelector extends ConsumerWidget {
  const ConfigSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final entity =
        ref.watch(entityStateProvider(HaEntities.configSelect)).valueOrNull;

    if (entity == null) return const SizedBox.shrink();

    final current = entity.state;
    final options =
        entity.attrList<String>('options') ?? [current];

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
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _OptionChip(
                  label: option,
                  selected: option == current,
                  onTap: option == current
                      ? null
                      : () => ref.read(haServiceProvider).call(
                            'input_select',
                            'select_option',
                            data: {
                              'entity_id': HaEntities.configSelect,
                              'option': option,
                            },
                          ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? tokens.onAccent.withValues(alpha: 0.15)
              : tokens.glassFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? tokens.onAccent.withValues(alpha: 0.6)
                : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? tokens.onAccent : tokens.offMuted,
          ),
        ),
      ),
    );
  }
}
