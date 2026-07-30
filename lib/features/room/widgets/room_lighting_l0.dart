import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/lighting_providers.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// The glance layer of room lighting: one-tap scene recall, a smart master, and
/// the adaptive-lighting toggle.
///
/// This is the surface the user meets first, so it holds intents rather than
/// dials — the sliders live one drill-down deeper, inside the layer cards.
class RoomLightingL0 extends ConsumerWidget {
  final RoomConfig room;

  const RoomLightingL0({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(roomLightingScenesProvider(room.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MasterControl(room: room),
        if (scenes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SceneChips(scenes: scenes),
        ],
        if (room.adaptiveLightingSwitch != null) ...[
          const SizedBox(height: 8),
          _AdaptiveLightingChip(entityId: room.adaptiveLightingSwitch!),
        ],
      ],
    );
  }
}

/// Master on/off for the whole room.
///
/// Off turns off every resolved fixture. On recalls the room's comfort scene
/// when one has been authored, else plainly turns the lighting on — so the
/// highest-frequency tap expresses an intent without ever becoming a no-op.
class _MasterControl extends ConsumerWidget {
  final RoomConfig room;

  const _MasterControl({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lighting = room.lighting;
    // Commanding the top-level units turns off their members transitively, so
    // this covers the room without firing redundant per-member calls.
    final units = lighting.controlUnitIds;
    if (units.isEmpty) return const SizedBox.shrink();

    final onCount = lighting.allFixtureIds
        .where((id) => ref.watch(entityStateProvider(id)).valueOrNull?.isOn ?? false)
        .length;
    final isOn = onCount > 0;

    final service = ref.read(haServiceProvider);
    final comfort = ref.watch(comfortSceneProvider(room.id));

    return ControlCard(
      icon: MdiIcons.lightbulbGroup,
      name: 'All ${room.name} lights',
      // Deliberately plain: HA scenes report no "active" state, so claiming
      // "Comfort" here would be a guess (D9).
      status: isOn ? '$onCount on' : 'Off',
      isOn: isOn,
      trailing: PowerToggle(
        isOn: isOn,
        onTap: () {
          if (isOn) {
            for (final id in units) {
              service.turnOff(id);
            }
            return;
          }
          if (comfort != null) {
            service.call('scene', 'turn_on', data: {'entity_id': comfort});
            return;
          }
          for (final id in units) {
            service.turnOn(id);
          }
        },
      ),
    );
  }
}

/// One-tap recall for the scenes that touch this room's lights.
class _SceneChips extends ConsumerWidget {
  final List<RoomScene> scenes;

  const _SceneChips({required this.scenes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(haServiceProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final scene in scenes)
          ActionChip(
            avatar: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(scene.name),
            onPressed: () => service
                .call('scene', 'turn_on', data: {'entity_id': scene.entityId}),
          ),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: OptionChip(
        icon: MdiIcons.themeLightDark,
        label: 'Adaptive lighting',
        selected: isOn,
        onToggle: (_) =>
            isOn ? service.turnOff(entityId) : service.turnOn(entityId),
      ),
    );
  }
}
