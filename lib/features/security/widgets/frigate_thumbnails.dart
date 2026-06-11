import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';

/// Row of recent Frigate event snapshots. Auto-refreshes every 30 s; tapping a
/// thumbnail opens the full image in a modal.
class FrigateThumbnails extends ConsumerStatefulWidget {
  const FrigateThumbnails({super.key});

  @override
  ConsumerState<FrigateThumbnails> createState() => _FrigateThumbnailsState();
}

class _FrigateThumbnailsState extends ConsumerState<FrigateThumbnails> {
  static const _entities = [
    (HaEntities.frigatePerson, 'Person'),
    (HaEntities.frigateBackpack, 'Backpack'),
  ];

  Timer? _timer;
  final Map<String, String> _urls = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final rest = ref.read(haRestClientProvider);
    for (final (id, _) in _entities) {
      final url =
          await rest.proxyImageUrl('/api/camera_proxy/$id', cacheBust: true);
      _urls[id] = url.toString();
    }
    if (mounted) setState(() {});
  }

  void _showFull(String url, String label) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(child: Image.network(url, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (id, label) in _entities)
            if (_urls[id] != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showFull(_urls[id]!, label),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          _urls[id]!,
                          width: 180,
                          height: 120,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Container(
                            width: 180,
                            height: 120,
                            color: Colors.black,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.white38),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(label,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
