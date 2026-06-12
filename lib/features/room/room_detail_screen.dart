import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/room_config.dart';
import 'package:ha_flutter/features/room/room_sections.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';
import 'package:ha_flutter/features/room/widgets/room_alert_strip.dart';
import 'package:ha_flutter/features/room/widgets/room_climate_section.dart';
import 'package:ha_flutter/features/room/widgets/room_lights_section.dart';
import 'package:ha_flutter/features/room/widgets/room_media_section.dart';
import 'package:ha_flutter/features/room/widgets/room_sidebar.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/env_reading.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Per-room detail with its own background, ambient light tinting, and the
/// room's device controls organised into concept sections. Wide windows
/// (≥ 840 dp) get a sidebar with bookmark nav + scrollable content pane;
/// narrow ones a compact scrollable list. Pushed from the room grid.
class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  // Highlighted bookmark — tracks last tapped, not scroll position.
  RoomSection? _selected;
  final _sectionKeys = <RoomSection, GlobalKey>{
    for (final s in RoomSection.values) s: GlobalKey(),
  };

  void _scrollTo(RoomSection section) {
    setState(() => _selected = section);
    final ctx = _sectionKeys[section]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomConfigProvider(widget.roomId));
    if (room == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Ambient tint from on lights → animated middle-gradient overlay (600 ms).
    final lights = [
      for (final id in room.allLights)
        ref.watch(entityStateProvider(id)).valueOrNull ??
            EntityState.unknown(id),
    ];
    final tint = HsColorConverter.ambientTint(lights, lightness: 0.15);

    final mediaState =
        room.mediaPlayer != null
            ? ref.watch(entityStateProvider(room.mediaPlayer!)).valueOrNull?.state
            : null;
    final sections = availableSections(
      room,
      mediaActive: isMediaActiveState(mediaState),
    );
    // Keep selected valid when sections change (e.g. media player turns off).
    final selected = (_selected != null && sections.contains(_selected))
        ? _selected
        : (sections.isEmpty ? null : sections.first);

    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutMinWidth;

    return Stack(
      children: [
        const Positioned.fill(child: AppBackground()),
        // Ambient room tint overlay.
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: tint ?? Colors.transparent),
              duration: const Duration(milliseconds: 600),
              builder: (context, color, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      color ?? Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          appBar: AppBar(
            // On wide layouts the room name lives in the sidebar.
            title: wide ? null : Text(room.name),
            actions: const [ConnectionChip()],
          ),
          body: SafeArea(
            child: wide
                ? _wideBody(room, sections, selected)
                : _compactBody(room, sections),
          ),
        ),
      ],
    );
  }

  Widget _wideBody(
      RoomConfig room, List<RoomSection> sections, RoomSection? selected) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: kRoomSidebarWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 24),
            child: RoomSidebar(
              room: room,
              sections: sections,
              selected: selected,
              onSelect: _scrollTo,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final section in sections) ...[
                  KeyedSubtree(
                    key: _sectionKeys[section],
                    child: _sectionContent(room, section, wide: true),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactBody(RoomConfig room, List<RoomSection> sections) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CompactHeader(room: room),
        const SizedBox(height: 12),
        RoomAlertStrip(roomId: room.id),
        const SizedBox(height: 12),
        for (final section in sections) ...[
          _sectionContent(room, section, wide: false),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _sectionContent(RoomConfig room, RoomSection section,
      {required bool wide}) {
    return switch (section) {
      RoomSection.climate => RoomClimateSection(room: room),
      RoomSection.lights => RoomLightsSection(room: room, wide: wide),
      RoomSection.media => RoomMediaSection(room: room),
    };
  }
}

/// Slim identity + environment row for the compact layout.
class _CompactHeader extends ConsumerWidget {
  final RoomConfig room;
  const _CompactHeader({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final areaIcons = ref.watch(areaIconsProvider).valueOrNull ?? {};
    final roomIcon = mdiIcon(areaIcons[room.id], fallback: MdiIcons.homeOutline);

    final readings = <Widget>[
      if (room.climate != null)
        EnvReading(
          entityId: room.climate!,
          kind: EnvKind.temperature,
          attribute: 'current_temperature',
        ),
      if (room.humiditySensor != null)
        EnvReading(entityId: room.humiditySensor!, kind: EnvKind.humidity),
      if (room.illuminanceSensor != null)
        EnvReading(entityId: room.illuminanceSensor!, kind: EnvKind.illuminance),
      if (room.pm25Sensor != null)
        EnvReading(entityId: room.pm25Sensor!, kind: EnvKind.pm25),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(roomIcon, size: 24, color: tokens.onAccent),
          const SizedBox(width: 12),
          Expanded(
            child: readings.isEmpty
                ? Text(room.name,
                    style: const TextStyle(fontWeight: FontWeight.w600))
                : Wrap(runSpacing: 4, children: readings),
          ),
        ],
      ),
    );
  }
}
