import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/widgets/lighting_layer_card.dart';
import 'package:ha_flutter/features/room/widgets/room_lighting_l0.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/capability_light_control.dart';

/// Lights & Ambiance section, presented as a progressively-disclosed surface:
/// the glance layer (scenes, master, adaptive lighting) above the room's
/// lighting-role layers, with unlabelled fixtures collected under "Other".
///
/// Dials are deliberately absent from the top level — they live inside each
/// layer's control, one drill-down away.
class RoomLightsSection extends ConsumerWidget {
  final RoomConfig room;
  final bool wide;

  const RoomLightsSection({super.key, required this.room, this.wide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final lighting = room.lighting;
    if (lighting.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns when there is room for them, so a wide window does not
        // leave layer cards stretched across the whole pane.
        final columns =
            wide && constraints.maxWidth >= kControlMaxWidth * 2 ? 2 : 1;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, kControlMaxWidth)
                : kControlMaxWidth);

        Widget sized(Widget child) =>
            SizedBox(width: itemWidth, child: child);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sized(RoomLightingL0(room: room)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final layer in lighting.layers)
                  sized(LightingLayerCard(layer: layer)),
              ],
            ),
            if (lighting.ungrouped.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Other',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.offMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final fixture in lighting.ungrouped)
                    sized(CapabilityLightControl(fixture: fixture)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
