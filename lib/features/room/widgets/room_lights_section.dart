import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/brightness_slider.dart';
import 'package:ha_flutter/shared/widgets/color_temperature_slider.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/light_tile.dart';
import 'package:ha_flutter/shared/widgets/light_toggle_widget.dart';

/// Lights & Ambiance section: group toggle, width-capped group sliders, an
/// adaptive-lighting chip, and the individual lights — an always-visible tile
/// grid on wide layouts, an expander-collapsed list on compact ones.
class RoomLightsSection extends ConsumerStatefulWidget {
  final RoomConfig room;
  final bool wide;
  const RoomLightsSection({super.key, required this.room, this.wide = false});

  @override
  ConsumerState<RoomLightsSection> createState() => _RoomLightsSectionState();
}

class _RoomLightsSectionState extends ConsumerState<RoomLightsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final room = widget.room;
    final group = room.lightGroup;
    final individuals = room.individualLights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group != null) ...[
          LightToggleWidget(entityId: group, name: 'All ${room.name} lights'),
          const SizedBox(height: 8),
          GlassCard(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kControlMaxWidth),
                child: Column(
                  children: [
                    BrightnessSlider(entityId: group),
                    ColorTemperatureSlider(entityId: group),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (room.adaptiveLightingSwitch != null) ...[
          const SizedBox(height: 8),
          _AdaptiveLightingChip(entityId: room.adaptiveLightingSwitch!),
        ],
        if (individuals.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (widget.wide)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final id in individuals)
                  SizedBox(width: 200, child: LightTile(entityId: id)),
              ],
            )
          else ...[
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _expanded ? 'Hide individual lights' : 'Show individual lights',
                style: TextStyle(color: tokens.offMuted),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  for (final id in individuals) ...[
                    LightTile(entityId: id),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ],
    );
  }
}

/// Toggle chip for the room's adaptive-lighting switch.
class _AdaptiveLightingChip extends ConsumerWidget {
  final String entityId;
  const _AdaptiveLightingChip({required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    if (state == null || state.isUnavailable) return const SizedBox.shrink();
    final isOn = state.isOn;
    final service = ref.read(haServiceProvider);

    return FilterChip(
      avatar: Icon(MdiIcons.themeLightDark, size: 18),
      label: const Text('Adaptive lighting'),
      selected: isOn,
      onSelected: (_) =>
          isOn ? service.turnOff(entityId) : service.turnOn(entityId),
    );
  }
}
