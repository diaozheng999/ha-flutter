import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/room_device.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/device_control_descriptor.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';
import 'package:ha_flutter/shared/widgets/reading_pill.dart';
import 'package:ha_flutter/shared/widgets/selection_chips.dart';

/// Air purifier rendered as a [ControlCard]: header icon, name, live status line
/// ("Auto · PM2.5 8"), and a [PowerToggle] acting on the power `switch` entity.
/// The body holds a mode [ModeSelector] (from the mode `select` options, disabled
/// while off) and [ReadingPill]s for PM2.5 (WHO severity) and filter life, which
/// stay visible while the purifier is off.
class AirPurifierWidget extends ConsumerWidget {
  final RoomDevice device;
  const AirPurifierWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerId = device.entity('power');
    final modeId = device.entity('mode');
    final d = DeviceControlDescriptor.describe(ref, device);

    final modeState =
        modeId != null ? ref.watch(entityStateProvider(modeId)).valueOrNull : null;
    final modes = modeState?.attrList<String>('options') ??
        const ['Auto', 'Sleep', 'Favorite'];
    final currentMode = modeState?.state;

    final service = ref.read(haServiceProvider);

    return PendingOverlay(
      entityId: powerId ?? device.deviceId,
      child: ControlCard(
        icon: d.icon,
        name: d.name,
        status: d.statusLine,
        isOn: d.isOn,
        unavailable: !d.isAvailable,
        trailing: PowerToggle(isOn: d.isOn, onTap: d.togglePower),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d.sensors.isNotEmpty)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [for (final s in d.sensors) ReadingPill(spec: s)],
              ),
            if (modeId != null) ...[
              const SizedBox(height: 12),
              ModeSelector<String>(
                options: modes,
                selected: currentMode,
                labelOf: (m) => m,
                onSelect: d.isOn
                    ? (m) => service.call('select', 'select_option',
                        data: {'entity_id': modeId, 'option': m})
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
