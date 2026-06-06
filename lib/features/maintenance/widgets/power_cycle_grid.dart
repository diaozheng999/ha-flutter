import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Grid of physical power-cycle relays. Each toggles only on long-press to
/// prevent accidental power cuts; a tap shows a "Hold to toggle" hint.
class PowerCycleGrid extends StatelessWidget {
  const PowerCycleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = constraints.maxWidth > 600 ? 2.4 : 2.0;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            for (final s in HaEntities.powerCycleSwitches)
              _PowerSwitch(label: s.label, entityId: s.entity),
          ],
        );
      },
    );
  }
}

class _PowerSwitch extends ConsumerWidget {
  final String label;
  final String entityId;
  const _PowerSwitch({required this.label, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    final isOn = state?.isOn ?? false;
    final service = ref.read(haServiceProvider);

    return GlassCard(
      glowColor: isOn ? tokens.onAccent : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hold to toggle'),
          duration: Duration(seconds: 1),
        ),
      ),
      onLongPress: () async {
        await service.toggle(entityId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label toggled'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Row(
        children: [
          Icon(
            isOn ? Icons.power : Icons.power_off,
            color: isOn ? tokens.onAccent : tokens.offMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(isOn ? 'On' : 'Off',
                    style: TextStyle(fontSize: 12, color: tokens.offMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
