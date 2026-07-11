import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/room/alerts/room_alert.dart';
import 'package:ha_flutter/features/room/alerts/room_alerts_provider.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Severity-ordered alert list for a room: a strip in the sidebar, a banner on
/// compact layouts. Renders nothing at all when the room is healthy.
class RoomAlertStrip extends ConsumerWidget {
  final String roomId;
  const RoomAlertStrip({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final alerts = ref.watch(roomAlertsProvider(roomId));
    if (alerts.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final (i, alert) in alerts.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Icon(_icon(alert.severity),
                    size: 20, color: _color(alert.severity, tokens)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        alert.condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: tokens.offMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _icon(RoomAlertSeverity s) => switch (s) {
        RoomAlertSeverity.safety => MdiIcons.alertOctagon,
        RoomAlertSeverity.activity => MdiIcons.bellRingOutline,
        RoomAlertSeverity.offline => MdiIcons.lanDisconnect,
        RoomAlertSeverity.maintenance => MdiIcons.wrenchOutline,
        RoomAlertSeverity.battery => MdiIcons.batteryAlertVariantOutline,
      };

  Color _color(RoomAlertSeverity s, AppTokens tokens) => switch (s) {
        RoomAlertSeverity.safety => tokens.severityCritical,
        // Informational blue — no severity token maps to it.
        RoomAlertSeverity.activity => const Color(0xFF64B5F6),
        RoomAlertSeverity.offline => tokens.offMuted,
        RoomAlertSeverity.maintenance => tokens.severityWarning,
        RoomAlertSeverity.battery => tokens.severityWarning,
      };
}
