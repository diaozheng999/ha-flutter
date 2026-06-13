import 'package:flutter/material.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/shared/widgets/media_mini_player.dart';

/// Media section: the room's mini player. Only built when the player is
/// active (the section availability check in room_sections.dart gates this).
class RoomMediaSection extends StatelessWidget {
  final RoomConfig room;
  const RoomMediaSection({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return MediaMiniPlayer(
      entityId: room.mediaPlayer!,
      contextLabel: room.mediaPlayer,
    );
  }
}
