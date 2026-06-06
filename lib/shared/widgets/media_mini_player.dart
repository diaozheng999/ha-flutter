import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Compact media player: album art, title/artist, and transport controls.
/// Gracefully degrades when metadata is absent (e.g. a TV on live broadcast).
class MediaMiniPlayer extends ConsumerWidget {
  final String entityId;

  /// Optional label (e.g. room name) shown above the title.
  final String? contextLabel;

  const MediaMiniPlayer({super.key, required this.entityId, this.contextLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final title = state.attrString('media_title') ?? '—';
    final artist = state.attrString('media_artist') ?? '—';
    final picture = state.attrString('entity_picture');
    final isPlaying = state.state == 'playing';
    final service = ref.read(haServiceProvider);

    String? artUrl;
    if (picture != null) {
      final base = ref.read(haConnectionProvider).instanceUrl;
      artUrl = picture.startsWith('http') ? picture : '$base$picture';
    }

    return GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: artUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          _placeholder(tokens),
                    )
                  : _placeholder(tokens),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contextLabel != null)
                  Text(
                    contextLabel!,
                    style: TextStyle(fontSize: 11, color: tokens.offMuted),
                  ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.offMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                service.call('media_player', 'media_previous_track',
                    data: {'entity_id': entityId}),
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            iconSize: 34,
            onPressed: () => service.call(
              'media_player',
              isPlaying ? 'media_pause' : 'media_play',
              data: {'entity_id': entityId},
            ),
            icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          ),
          IconButton(
            onPressed: () => service.call('media_player', 'media_next_track',
                data: {'entity_id': entityId}),
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) => ColoredBox(
        color: tokens.glassFill,
        child: Icon(Icons.music_note, color: tokens.offMuted),
      );
}
