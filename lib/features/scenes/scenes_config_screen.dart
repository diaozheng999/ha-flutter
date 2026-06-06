import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/home/widgets/scene_launch_row.dart';
import 'package:ha_flutter/features/scenes/scenes_providers.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Scenes tab: scene tile grid, configuration mode selector, and per-room
/// adaptive lighting controls.
class ScenesConfigScreen extends ConsumerWidget {
  const ScenesConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenes'),
        actions: const [ConnectionChip()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _SectionLabel('Scenes'),
            const SizedBox(height: 8),
            scenes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load scenes'),
              data: (list) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  for (final s in list)
                    SceneTile(entityId: s.entityId, name: s.friendlyName),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Configuration'),
            const SizedBox(height: 8),
            const _ConfigSelector(),
            const SizedBox(height: 20),
            const _SectionLabel('Adaptive Lighting'),
            const SizedBox(height: 8),
            const _AdaptiveLightingSection(),
          ],
        ),
      ),
    );
  }
}

class _ConfigSelector extends ConsumerWidget {
  const _ConfigSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(entityStateProvider(HaEntities.configSelect)).valueOrNull;
    if (state == null) return const SizedBox.shrink();
    final options = state.attrList<String>('options') ?? const [];
    final current = state.state;
    final service = ref.read(haServiceProvider);

    void select(String option) => service.call(
          'input_select',
          'select_option',
          data: {'entity_id': HaEntities.configSelect, 'option': option},
        );

    if (options.length <= 4) {
      return GlassCard(
        child: SegmentedButton<String>(
          segments: [
            for (final o in options) ButtonSegment(value: o, label: Text(o)),
          ],
          selected: {if (options.contains(current)) current},
          showSelectedIcon: false,
          onSelectionChanged: (s) => select(s.first),
        ),
      );
    }

    return GlassCard(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final o in options)
                  ListTile(
                    title: Text(o),
                    trailing: o == current ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(context).pop(o),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) select(picked);
      },
      child: Row(
        children: [
          const Icon(Icons.tune),
          const SizedBox(width: 12),
          Text('Mode', style: TextStyle(color: context.tokens.offMuted)),
          const Spacer(),
          Text(current, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _AdaptiveLightingSection extends ConsumerWidget {
  const _AdaptiveLightingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final room in HaEntities.roomsWithAdaptiveLighting)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AdaptiveRow(
              roomName: room.name,
              switchEntity: room.adaptiveLightingSwitch!,
            ),
          ),
      ],
    );
  }
}

class _AdaptiveRow extends ConsumerWidget {
  final String roomName;
  final String switchEntity;
  const _AdaptiveRow({required this.roomName, required this.switchEntity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entityStateProvider(switchEntity)).valueOrNull;
    final isOn = state?.isOn ?? false;
    final service = ref.read(haServiceProvider);

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Text(roomName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Opacity(
            opacity: isOn ? 1 : 0.4,
            child: TextButton.icon(
              onPressed: isOn
                  ? () => service.call(
                        'adaptive_lighting',
                        'set_manual_control',
                        data: {
                          'entity_id': switchEntity,
                          'manual_control': true,
                        },
                      )
                  : null,
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Pause 1h'),
            ),
          ),
          Switch(
            value: isOn,
            onChanged: (v) =>
                v ? service.turnOn(switchEntity) : service.turnOff(switchEntity),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
}
