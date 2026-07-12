import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';

/// A light group control rendered as a [ControlCard]: header icon, name, live
/// status line, and a [PowerToggle] that calls `light.turn_on` / `light.turn_off`.
/// The card glows in the light's `hs_color` (warm-white fallback) when on, animated
/// over 300 ms by [GlassCard]; unavailable lights render dimmed and disabled.
class LightToggleWidget extends ConsumerWidget {
  final String entityId;
  final String? name;

  /// Individual light entities in the room, used for the "N on" status count.
  final List<String> individualLights;

  const LightToggleWidget({
    super.key,
    required this.entityId,
    this.name,
    this.individualLights = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = RoomDevice(
      deviceId: entityId,
      name: name ?? 'Lights',
      role: DeviceRole.light,
      entities: {'primary': entityId},
      isGroup: true,
    );
    final d = DeviceControlDescriptor.describe(ref, device,
        roomLights: individualLights);

    return PendingOverlay(
      entityId: entityId,
      child: ControlCard(
        icon: d.icon,
        name: d.name,
        status: d.statusLine,
        isOn: d.isOn,
        unavailable: !d.isAvailable,
        glowColor: d.glowColor,
        trailing: PowerToggle(isOn: d.isOn, onTap: d.togglePower),
      ),
    );
  }
}
