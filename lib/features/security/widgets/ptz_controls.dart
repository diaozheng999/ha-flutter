import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Pan/tilt/zoom controls for the living room camera: a directional pad that
/// presses the PTZ button entities, plus pan/tilt degree sliders.
class PtzControls extends ConsumerWidget {
  const PtzControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(haServiceProvider);
    void press(String button) =>
        service.call('button', 'press', data: {'entity_id': button});

    return GlassCard(
      child: Column(
        children: [
          // Directional pad.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => press(HaEntities.camTiltUp),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => press(HaEntities.camPanLeft),
                icon: const Icon(Icons.keyboard_arrow_left),
              ),
              const SizedBox(width: 48),
              IconButton.filledTonal(
                onPressed: () => press(HaEntities.camPanRight),
                icon: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => press(HaEntities.camTiltDown),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DegreeSlider(
            label: 'Pan',
            entityId: HaEntities.camPanDegrees,
            min: 1,
            max: 90,
          ),
          _DegreeSlider(
            label: 'Tilt',
            entityId: HaEntities.camTiltDegrees,
            min: 1,
            max: 45,
          ),
        ],
      ),
    );
  }
}

class _DegreeSlider extends ConsumerStatefulWidget {
  final String label;
  final String entityId;
  final double min;
  final double max;
  const _DegreeSlider({
    required this.label,
    required this.entityId,
    required this.min,
    required this.max,
  });

  @override
  ConsumerState<_DegreeSlider> createState() => _DegreeSliderState();
}

class _DegreeSliderState extends ConsumerState<_DegreeSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    final live = double.tryParse(state?.state ?? '') ?? widget.min;
    final value = (_dragValue ?? live).clamp(widget.min, widget.max);

    return Row(
      children: [
        SizedBox(width: 36, child: Text(widget.label, style: TextStyle(color: tokens.offMuted))),
        Expanded(
          child: Slider(
            value: value,
            min: widget.min,
            max: widget.max,
            label: value.round().toString(),
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              ref.read(haServiceProvider).call(
                'number',
                'set_value',
                data: {'entity_id': widget.entityId, 'value': v.round()},
              );
              setState(() => _dragValue = null);
            },
          ),
        ),
        SizedBox(
          width: 32,
          child: Text('${value.round()}',
              textAlign: TextAlign.end, style: tokens.sensorStyle),
        ),
      ],
    );
  }
}
