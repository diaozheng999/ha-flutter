import 'package:flutter/material.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/room_sections.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/quick_control_tile.dart';

/// The room's quick-controls layer: one [QuickControlTile] per on/off-capable
/// device. Renders as a vertical block in the wide sidebar and as a horizontal
/// scrolling strip on compact layouts. [onOpen] navigates to a device's detailed
/// control section.
class RoomQuickControls extends StatelessWidget {
  final RoomConfig room;
  final bool horizontal;
  final void Function(RoomSection) onOpen;

  const RoomQuickControls({
    super.key,
    required this.room,
    required this.onOpen,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final devices = room.quickControlDevices;
    if (devices.isEmpty) return const SizedBox.shrink();

    QuickControlTile tile(RoomDevice device) => QuickControlTile(
          device: device,
          roomLights:
              device.role == DeviceRole.light ? room.individualLights : const [],
          onOpen: () => onOpen(sectionForDevice(device)),
        );

    if (horizontal) {
      return SizedBox(
        height: 62,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: devices.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) =>
              SizedBox(width: 200, child: tile(devices[i])),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < devices.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          tile(devices[i]),
        ],
      ],
    );
  }
}
