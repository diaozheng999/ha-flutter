import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/app_shell.dart';
import 'package:ha_flutter/features/home/home_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Horizontal summary of what's currently active. Shows "All quiet" when the
/// house is idle. Chips switch to a relevant tab on tap.
class ActiveDevicesBar extends ConsumerWidget {
  const ActiveDevicesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final lights = ref.watch(lightsOnCountProvider);
    final fans = ref.watch(fansOnCountProvider);
    final acs = ref.watch(acsActiveCountProvider);
    final vacuum = ref.watch(vacuumActiveProvider);

    final chips = <Widget>[
      if (lights > 0)
        _chip(context, Icons.lightbulb, '$lights on', tokens.onAccent,
            () => _goTab(ref, 1)),
      if (fans > 0)
        _chip(context, Icons.mode_fan_off, '$fans fan${fans > 1 ? 's' : ''}',
            tokens.onAccent, () => _goTab(ref, 1)),
      if (acs > 0)
        _chip(context, Icons.ac_unit, '$acs AC${acs > 1 ? 's' : ''}',
            tokens.onAccent, () => _goTab(ref, 1)),
      if (vacuum)
        _chip(context, Icons.cleaning_services, 'Cleaning', tokens.onAccent,
            null),
    ];

    if (chips.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.nightlight_round, color: tokens.offMuted, size: 18),
            const SizedBox(width: 8),
            Text('All quiet', style: TextStyle(color: tokens.offMuted)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  void _goTab(WidgetRef ref, int index) =>
      ref.read(activeTabProvider.notifier).state = index;

  Widget _chip(BuildContext context, IconData icon, String label, Color color,
      VoidCallback? onTap) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
