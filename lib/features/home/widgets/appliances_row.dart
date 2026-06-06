import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Row of appliance status cards on the home screen.
class AppliancesRow extends StatelessWidget {
  const AppliancesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          SizedBox(width: 200, child: _ShinyCard()),
          SizedBox(width: 12),
          SizedBox(width: 200, child: _WashingMachineCard()),
          SizedBox(width: 12),
          SizedBox(width: 200, child: _WaterHeaterCard()),
        ],
      ),
    );
  }
}

class _ShinyCard extends ConsumerStatefulWidget {
  const _ShinyCard();

  @override
  ConsumerState<_ShinyCard> createState() => _ShinyCardState();
}

class _ShinyCardState extends ConsumerState<_ShinyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(HaEntities.vacuum)).valueOrNull;
    final value = state?.state ?? 'unknown';
    final cleaning = value == 'cleaning';
    final isError = value == 'error';
    final canStart = value == 'docked' || value == 'idle';
    final canReturn = value == 'cleaning' || value == 'paused';
    final service = ref.read(haServiceProvider);

    if (cleaning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!cleaning && _spin.isAnimating) {
      _spin.stop();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RotationTransition(
                turns: _spin,
                child: Icon(
                  Icons.cleaning_services,
                  color: isError ? const Color(0xFFEF5350) : tokens.onAccent,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Shiny', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(
            isError ? 'Error' : _label(value),
            style: TextStyle(
              color: isError ? const Color(0xFFEF5350) : tokens.offMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (!isError)
            Row(
              children: [
                if (canStart)
                  FilledButton.tonal(
                    onPressed: () => service.call('vacuum', 'start',
                        data: {'entity_id': HaEntities.vacuum}),
                    child: const Text('Start'),
                  ),
                if (canReturn)
                  FilledButton.tonal(
                    onPressed: () => service.call('vacuum', 'return_to_base',
                        data: {'entity_id': HaEntities.vacuum}),
                    child: const Text('Return'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _label(String s) => switch (s) {
        'docked' => 'Docked',
        'cleaning' => 'Cleaning',
        'returning' => 'Returning',
        'paused' => 'Paused',
        'idle' => 'Idle',
        _ => 'Unknown',
      };
}

class _WashingMachineCard extends ConsumerWidget {
  const _WashingMachineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final status =
        ref.watch(entityStateProvider(HaEntities.washerStatus)).valueOrNull;
    final timeLeft =
        ref.watch(entityStateProvider(HaEntities.washerTimeLeft)).valueOrNull;
    final minutes = double.tryParse(timeLeft?.state ?? '') ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_laundry_service_outlined, color: tokens.offMuted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Washer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Text(status?.state ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (minutes > 0)
            Text('${minutes.round()}m remaining',
                style: TextStyle(fontSize: 12, color: tokens.offMuted)),
        ],
      ),
    );
  }
}

class _WaterHeaterCard extends ConsumerWidget {
  const _WaterHeaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state =
        ref.watch(entityStateProvider(HaEntities.waterHeater)).valueOrNull;
    final isUnknown = state == null || state.isUnknown || state.isUnavailable;
    final temp = state?.attrDouble('current_temperature');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_damage_outlined, color: tokens.offMuted),
              const SizedBox(width: 8),
              const Text('Heater', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(
            temp != null ? '${temp.toStringAsFixed(1)}°C' : '—',
            style: tokens.sensorStyle.copyWith(fontSize: 24),
          ),
          Text(
            isUnknown ? 'Unknown' : (state.isOn ? 'On' : 'Off'),
            style: TextStyle(fontSize: 12, color: tokens.offMuted),
          ),
        ],
      ),
    );
  }
}
