import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Control tile for a Xiaomi-style air purifier: power toggle, mode chips,
/// live PM2.5 reading, and filter life. Entity IDs come from [RoomDevice].
class AirPurifierWidget extends ConsumerWidget {
  final RoomDevice device;
  const AirPurifierWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final service = ref.read(haServiceProvider);

    final powerId = device.entity('power');
    final modeId = device.entity('mode');
    final pm25Id = device.entity('pm25');
    final filterId = device.entity('filter');

    final powerState = powerId != null
        ? ref.watch(entityStateProvider(powerId)).valueOrNull
        : null;
    final modeState = modeId != null
        ? ref.watch(entityStateProvider(modeId)).valueOrNull
        : null;
    final pm25State = pm25Id != null
        ? ref.watch(entityStateProvider(pm25Id)).valueOrNull
        : null;
    final filterState = filterId != null
        ? ref.watch(entityStateProvider(filterId)).valueOrNull
        : null;

    final isOn = powerState?.isOn ?? false;
    final currentMode = modeState?.state;
    final pm25 = pm25State?.state;
    final filterPct = filterState?.state;

    // Modes available from HA select options attribute.
    final modes = modeState?.attrList<String>('options') ??
        const ['Auto', 'Sleep', 'Favorite'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header: icon + name + power toggle
        Row(
          children: [
            Icon(
              Icons.air,
              size: 20,
              color: isOn ? tokens.onAccent : tokens.offMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (powerId != null)
              Switch(
                value: isOn,
                onChanged: (_) => isOn
                    ? service.turnOff(powerId)
                    : service.turnOn(powerId),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // PM2.5 reading
        if (pm25 != null)
          Row(
            children: [
              Icon(Icons.grain, size: 14, color: tokens.offMuted),
              const SizedBox(width: 4),
              Text(
                '$pm25 μg/m³',
                style: TextStyle(fontSize: 13, color: tokens.offMuted),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Mode chips
        if (modeId != null)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final mode in modes)
                ChoiceChip(
                  label: Text(mode),
                  selected: mode == currentMode,
                  onSelected: isOn
                      ? (_) => service.call(
                            'select',
                            'select_option',
                            data: {
                              'entity_id': modeId,
                              'option': mode,
                            },
                          )
                      : null,
                ),
            ],
          ),
        // Filter life footer
        if (filterPct != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.filter_alt_outlined,
                  size: 13, color: tokens.offMuted),
              const SizedBox(width: 4),
              Text(
                'Filter $filterPct%',
                style: TextStyle(fontSize: 12, color: tokens.offMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
