import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';

/// Authenticated camera view via HA's image proxy. Refreshes the still image on
/// a timer — ~1 s while [active], 2 s when the tab is backgrounded — giving a
/// near-live feed without an MJPEG decoder dependency, and satisfying the
/// "pause to still refresh when inactive" requirement.
class CameraView extends ConsumerStatefulWidget {
  final String entityId;
  final bool active;
  final double aspectRatio;
  const CameraView({
    super.key,
    required this.entityId,
    required this.active,
    this.aspectRatio = 16 / 9,
  });

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> {
  Timer? _timer;
  String? _url;

  @override
  void initState() {
    super.initState();
    _refresh();
    _restartTimer();
  }

  @override
  void didUpdateWidget(CameraView old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: widget.active ? 1000 : 2000),
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final url = await ref.read(haRestClientProvider).proxyImageUrl(
            '/api/camera_proxy/${widget.entityId}',
            cacheBust: true,
          );
      if (mounted) setState(() => _url = url.toString());
    } catch (_) {
      // Ignore network errors on background/initial refresh
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: _url == null
            ? const ColoredBox(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              )
            : Image.network(
                _url!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Icon(Icons.videocam_off, color: Colors.white54),
                  ),
                ),
              ),
      ),
    );
  }
}
