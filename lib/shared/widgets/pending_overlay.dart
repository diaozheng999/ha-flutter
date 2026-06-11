import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';

/// Wraps a control and overlays a spinner while a service call targeting
/// [entityId] is in flight. The spinner only appears after a 500 ms grace
/// period so fast LAN calls don't flicker it.
class PendingOverlay extends ConsumerStatefulWidget {
  final String entityId;
  final Widget child;
  const PendingOverlay({
    super.key,
    required this.entityId,
    required this.child,
  });

  @override
  ConsumerState<PendingOverlay> createState() => _PendingOverlayState();
}

class _PendingOverlayState extends ConsumerState<PendingOverlay> {
  bool _showSpinner = false;

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(entityPendingProvider(widget.entityId));

    if (pending && !_showSpinner) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            ref.read(entityPendingProvider(widget.entityId))) {
          setState(() => _showSpinner = true);
        }
      });
    } else if (!pending && _showSpinner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showSpinner = false);
      });
    }

    return Stack(
      children: [
        widget.child,
        if (_showSpinner)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
