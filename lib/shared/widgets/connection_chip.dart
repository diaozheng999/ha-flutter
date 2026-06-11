import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';

/// Amber "Reconnecting…" chip shown in app bars while the WebSocket is not
/// connected. Renders nothing when connected.
class ConnectionChip extends ConsumerWidget {
  const ConnectionChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider).valueOrNull ??
        ConnectionStatus.connecting;
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: const Color(0x33FFB300),
        side: const BorderSide(color: Color(0x66FFB300)),
        avatar: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB300)),
        ),
        label: const Text('Reconnecting…', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

/// Builds a transparent app bar with the connection chip appended to [actions].
AppBar haAppBar(String title, {List<Widget> actions = const []}) {
  return AppBar(
    title: Text(title),
    actions: [...actions, const ConnectionChip()],
  );
}
