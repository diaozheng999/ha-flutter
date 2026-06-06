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
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
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
    final glow = anyOn ? HsColorConverter.ambientTint(lights, lightness: 0.45) : null;

    return GlassCard(
      glowColor: glow,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RoomDetailScreen(roomId: room.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(room.icon, color: anyOn ? tokens.onAccent : tokens.offMuted),
              const Spacer(),
              if (anyOn)
                Icon(Icons.lightbulb, size: 16, color: tokens.onAccent),
            ],
          ),
          const Spacer(),
          Text(
            room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (room.climate != null)
                EnvReading(
                  entityId: room.climate!,
                  kind: EnvKind.temperature,
                  attribute: 'current_temperature',
                ),
              Text(
                anyOn ? 'Lights on' : 'Off',
                style: TextStyle(fontSize: 12, color: tokens.offMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
