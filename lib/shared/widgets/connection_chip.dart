import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// "Reconnecting…" chip shown in app bars while the WebSocket is not connected,
/// tinted with the shared caution (severity-warning) token. Renders nothing when
/// connected.
class ConnectionChip extends ConsumerWidget {
  const ConnectionChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final status = ref.watch(connectionStatusProvider).valueOrNull ??
        ConnectionStatus.connecting;
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();

    final caution = tokens.severityWarning;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: caution.withValues(alpha: 0.2),
        side: BorderSide(color: caution.withValues(alpha: 0.4)),
        avatar: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: caution),
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
