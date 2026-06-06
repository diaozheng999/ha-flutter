import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/room_detail_screen.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';

/// Responsive grid of room cards. Columns adapt to width (2 on phones, 3+ on
/// wide / desktop windows).
class RoomGrid extends StatelessWidget {
  const RoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 3
                : 2;
        final ratio = constraints.maxWidth > 900
            ? 1.5
            : constraints.maxWidth > 600
                ? 1.4
                : 1.3;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            for (final room in HaEntities.rooms) RoomCard(room: room),
          ],
        );
      },
    );
  }
}

class RoomCard extends ConsumerWidget {
  final RoomConfig room;
  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    final lights = [
      for (final id in room.allLights)
        ref.watch(entityStateProvider(id)).valueOrNull ??
            EntityState.unknown(id),
    ];
    final anyOn = lights.any((l) => l.isOn);
    final glow =
        anyOn ? HsColorConverter.ambientTint(lights, lightness: 0.45) : null;

    final fanOn = room.fan != null &&
        (ref.watch(entityStateProvider(room.fan!)).valueOrNull?.isOn ?? false);

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
              Icon(room.icon,
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
                      anyOn ? Icons.lightbulb : Icons.lightbulb_outline,
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
          // Status row: AC temp, fan, light summary
          Row(
            children: [
              if (room.climate != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: EnvReading(
                    entityId: room.climate!,
                    kind: EnvKind.temperature,
                    attribute: 'current_temperature',
                  ),
                ),
              if (fanOn)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.air,
                      size: 14, color: tokens.onAccent.withValues(alpha: 0.8)),
                ),
              if (acActive)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.ac_unit,
                      size: 14, color: tokens.onAccent.withValues(alpha: 0.8)),
                ),
              Expanded(
                child: Text(
                  anyOn
                      ? '${lights.where((l) => l.isOn).length} light${lights.where((l) => l.isOn).length == 1 ? '' : 's'}'
                      : 'Off',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.offMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
