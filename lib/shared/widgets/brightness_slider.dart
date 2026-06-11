import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';

/// Brightness slider mapping the HA `brightness` attribute (0–255) to 0–100%.
/// Dragging to 0 turns the light off; service calls are debounced at 200 ms.
class BrightnessSlider extends ConsumerStatefulWidget {
  final String entityId;
  const BrightnessSlider({super.key, required this.entityId});

  @override
  ConsumerState<BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends ConsumerState<BrightnessSlider> {
  final _debouncer = Debouncer();
  double? _dragValue; // local override while dragging

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    final brightness = state?.attrInt('brightness') ?? 0;
    final livePct = (brightness / 255 * 100).clamp(0, 100).toDouble();
    final value = _dragValue ?? livePct;

    return Row(
      children: [
        Icon(Icons.brightness_6_outlined, size: 20, color: tokens.offMuted),
        Expanded(
          child: Slider(
            value: value,
            max: 100,
            label: '${value.round()}%',
            divisions: 100,
            onChanged: (v) {
              setState(() => _dragValue = v);
              _debouncer.call(() => _apply(v));
            },
            onChangeEnd: (v) {
              _apply(v);
              setState(() => _dragValue = null);
            },
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${value.round()}%',
            textAlign: TextAlign.end,
            style: tokens.sensorStyle,
          ),
        ),
      ],
    );
  }

  void _apply(double pct) {
    final service = ref.read(haServiceProvider);
    if (pct <= 0) {
      service.turnOff(widget.entityId);
    } else {
      service.turnOn(widget.entityId, {'brightness_pct': pct.round()});
    }
  }
}
