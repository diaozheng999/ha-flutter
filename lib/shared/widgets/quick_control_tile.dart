import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';

/// A compact at-a-glance tile for one on/off-capable device. Tapping anywhere on
/// the tile toggles the device's power via its descriptor; the trailing chevron
/// (or a long-press) opens the detailed control. Its on state follows the
/// rationed-glow rule (D10). Each tile is its own [ConsumerWidget] observing only
/// its device's entities, so a single device update doesn't rebuild siblings.
class QuickControlTile extends ConsumerWidget {
  final RoomDevice device;
  final List<String> roomLights;

  /// Opens the device's detailed control (chevron tap / long-press).
  final VoidCallback? onOpen;

  const QuickControlTile({
    super.key,
    required this.device,
    this.roomLights = const [],
    this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final d = DeviceControlDescriptor.describe(ref, device,
        roomLights: roomLights);
    final entityId = device.entity('primary') ??
        device.entity('power') ??
        device.deviceId;

    return PendingOverlay(
      entityId: entityId,
      child: GlassCard(
        glowColor: d.glowColor,
        dimmed: !d.isAvailable,
        onTap: d.togglePower,
        onLongPress: onOpen,
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            Icon(d.icon,
                size: 20, color: d.isOn ? tokens.onAccent : tokens.offMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    d.statusLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.offMuted),
                  ),
                ],
              ),
            ),
            if (onOpen != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onOpen,
                icon: Icon(Icons.chevron_right, color: tokens.offMuted),
                tooltip: 'Open ${d.name}',
              ),
          ],
        ),
      ),
    );
  }
}
