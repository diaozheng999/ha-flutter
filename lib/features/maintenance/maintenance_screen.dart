import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/maintenance/maintenance_providers.dart';
import 'package:ha_flutter/features/maintenance/widgets/db_cabinet.dart';
import 'package:ha_flutter/features/maintenance/widgets/power_cycle_grid.dart';
import 'package:ha_flutter/features/maintenance/widgets/vacuum_map.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Maintenance tab: HA update status, power-cycle relays, DB cabinet monitor,
/// and the vacuum map.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: const [ConnectionChip()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [
            _UpdatesBadge(),
            SizedBox(height: 20),
            _SectionLabel('Power Cycling'),
            SizedBox(height: 8),
            _HoldHint(),
            SizedBox(height: 8),
            PowerCycleGrid(),
            SizedBox(height: 20),
            DbCabinet(),
            SizedBox(height: 20),
            VacuumMap(),
          ],
        ),
      ),
    );
  }
}

class _UpdatesBadge extends ConsumerWidget {
  const _UpdatesBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final count = ref.watch(updateCountProvider).valueOrNull ?? 0;
    final upToDate = count == 0;

    return GlassCard(
      child: Row(
        children: [
          Icon(
            upToDate ? Icons.check_circle_outline : Icons.system_update,
            color: upToDate ? const Color(0xFF66BB6A) : tokens.onAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              upToDate
                  ? 'Up to date'
                  : '$count update${count > 1 ? 's' : ''} available',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: upToDate ? const Color(0xFF66BB6A) : null,
              ),
            ),
          ),
          if (!upToDate)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.onAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text('$count', style: tokens.sensorStyle),
            ),
        ],
      ),
    );
  }
}

class _HoldHint extends StatelessWidget {
  const _HoldHint();

  @override
  Widget build(BuildContext context) => Text(
        'These cut power to fixtures. Hold a tile to toggle.',
        style: TextStyle(fontSize: 12, color: context.tokens.offMuted),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
}
