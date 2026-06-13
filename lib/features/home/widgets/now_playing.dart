import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/home/home_providers.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';
import 'package:ha_flutter/shared/widgets/media_mini_player.dart';

/// Now-playing widget: appears when any media player is playing and cycles
/// across multiple active players every few seconds.
class NowPlaying extends ConsumerStatefulWidget {
  const NowPlaying({super.key});

  @override
  ConsumerState<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends ConsumerState<NowPlaying> {
  int _index = 0;
  Timer? _cycle;

  @override
  void dispose() {
    _cycle?.cancel();
    super.dispose();
  }

  String _roomFor(String mediaPlayer) {
    final rooms = ref.read(roomConfigsProvider).valueOrNull ?? [];
    return rooms.where((r) => r.mediaPlayer == mediaPlayer).firstOrNull?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(playingMediaProvider);

    // Manage the cycling timer based on how many players are active.
    if (playing.length > 1) {
      _cycle ??= Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) setState(() => _index++);
      });
    } else {
      _cycle?.cancel();
      _cycle = null;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: playing.isEmpty
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Builder(
              key: ValueKey(playing[_index % playing.length]),
              builder: (context) {
                final id = playing[_index % playing.length];
                return MediaMiniPlayer(entityId: id, contextLabel: _roomFor(id));
              },
            ),
    );
  }
}
