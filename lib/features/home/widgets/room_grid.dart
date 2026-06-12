import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/room_detail_screen.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';

/// Responsive grid of room cards. Columns adapt to width (2 on phones, 3+ on
/// wide / desktop windows).
class RoomGrid extends ConsumerWidget {
  const RoomGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomConfigsProvider).valueOrNull ?? [];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 3 : 2;
        final ratio = constraints.maxWidth > 900 ? 1.5 : 1.3;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [for (final room in rooms) RoomCard(room: room)],
        );
      },
    );
  }
}

class RoomCard extends ConsumerWidget {
  final RoomConfig room;
  const RoomCard({super.key, required this.room});

  static String _acModeLabel(String? state) => switch (state) {
        'cool' => 'Cooling',
        'heat' => 'Heating',
        'dry' => 'Dry',
        'fan_only' => 'Fan',
        'auto' => 'Auto',
        _ => state ?? '',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final areaIcons = ref.watch(areaIconsProvider).valueOrNull ?? {};
    final roomIcon = mdiIcon(
      areaIcons[room.id],
      fallback: MdiIcons.homeOutline,
    );

    final lights = [
      for (final id in room.allLights)
        ref.watch(entityStateProvider(id)).valueOrNull ??
            EntityState.unknown(id),
    ];
    final anyOn = lights.any((l) => l.isOn);
    final glow =
        anyOn ? HsColorConverter.ambientTint(lights, lightness: 0.45) : null;

    final acState = room.climate != null
        ? ref.watch(entityStateProvider(room.climate!)).valueOrNull?.state
        : null;
    final acActive =
        acState != null && acState != 'off' && acState != 'unavailable';

    final lightGroupId = room.lightGroup;

    return GlassCard(
      glowColor: glow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RoomDetailScreen(roomId: room.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: room icon + quick-toggle light button
          Row(
            children: [
              Icon(roomIcon,
                  size: 20,
                  color: anyOn ? tokens.onAccent : tokens.offMuted),
              const Spacer(),
              if (lightGroupId != null)
                PendingOverlay(
                  entityId: lightGroupId,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref.read(haServiceProvider).toggle(lightGroupId);
                    },
                    child: Icon(
                      anyOn ? MdiIcons.lightbulb : MdiIcons.lightbulbOutline,
                      size: 18,
                      color: anyOn ? tokens.onAccent : tokens.offMuted,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          // Status row: temperature + AC mode
          Row(
            children: [
              if (room.climate != null)
                EnvReading(
                  entityId: room.climate!,
                  kind: EnvKind.temperature,
                  attribute: 'current_temperature',
                ),
              if (acActive)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(MdiIcons.airConditioner,
                          size: 13, color: tokens.onAccent.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text(
                        _acModeLabel(acState),
                        style: TextStyle(fontSize: 12, color: tokens.offMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
