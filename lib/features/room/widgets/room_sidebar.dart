import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/room/room_sections.dart';
import 'package:ha_flutter/features/room/widgets/room_alert_strip.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Wide-layout room sidebar: identity, environment summary, alert strip, and
/// bookmark nav that scrolls the content pane to each section.
class RoomSidebar extends ConsumerWidget {
  final RoomConfig room;
  final List<RoomSection> sections;
  final RoomSection? selected;
  final ValueChanged<RoomSection> onSelect;

  const RoomSidebar({
    super.key,
    required this.room,
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final areaIcons = ref.watch(areaIconsProvider).valueOrNull ?? {};
    final roomIcon = mdiIcon(areaIcons[room.id], fallback: MdiIcons.homeOutline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(roomIcon, size: 32, color: tokens.onAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              ..._envReadings(room).map((r) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: r,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RoomAlertStrip(roomId: room.id),
        const SizedBox(height: 12),
        if (sections.length > 1)
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final section in sections)
                  _BookmarkItem(
                    section: section,
                    statusLine: sectionStatusLine(ref, room, section),
                    selected: section == selected,
                    onTap: () => onSelect(section),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static List<Widget> _envReadings(RoomConfig room) => [
        if (room.climate != null)
          EnvReading(
            entityId: room.climate!,
            kind: EnvKind.temperature,
            attribute: 'current_temperature',
          ),
        if (room.humiditySensor != null)
          EnvReading(entityId: room.humiditySensor!, kind: EnvKind.humidity),
        if (room.illuminanceSensor != null)
          EnvReading(
              entityId: room.illuminanceSensor!, kind: EnvKind.illuminance),
        if (room.pm25Sensor != null)
          EnvReading(entityId: room.pm25Sensor!, kind: EnvKind.pm25),
      ];
}

class _BookmarkItem extends StatelessWidget {
  final RoomSection section;
  final String statusLine;
  final bool selected;
  final VoidCallback onTap;

  const _BookmarkItem({
    required this.section,
    required this.statusLine,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? scheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(section.icon,
                  size: 22,
                  color: selected ? tokens.onAccent : tokens.offMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      statusLine,
                      style: TextStyle(fontSize: 12, color: tokens.offMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
