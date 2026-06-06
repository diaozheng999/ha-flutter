import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';

/// Colour-temperature slider over a warm→cool gradient track. Renders only when
/// the light supports `color_temp`. Service calls are debounced at 200 ms.
class ColorTemperatureSlider extends ConsumerStatefulWidget {
  final String entityId;
  const ColorTemperatureSlider({super.key, required this.entityId});

  @override
  ConsumerState<ColorTemperatureSlider> createState() =>
      _ColorTemperatureSliderState();
}

class _ColorTemperatureSliderState
    extends ConsumerState<ColorTemperatureSlider> {
  final _debouncer = Debouncer();
  double? _dragValue;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final modes = state.attrList<String>('supported_color_modes') ?? const [];
    if (!modes.contains('color_temp')) return const SizedBox.shrink();

    final minK = state.attrInt('min_color_temp_kelvin') ?? 2000;
    final maxK = state.attrInt('max_color_temp_kelvin') ?? 6500;
    final current = state.attrInt('color_temp_kelvin') ?? minK;
    final value =
        _dragValue ?? current.clamp(minK, maxK).toDouble();

    return Row(
      children: [
        Icon(Icons.thermostat_outlined, size: 20, color: tokens.offMuted),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              trackShape: const _GradientTrackShape(),
            ),
            child: Slider(
              value: value,
              min: minK.toDouble(),
              max: maxK.toDouble(),
              label: '${value.round()}K',
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
        ),
        SizedBox(
          width: 56,
          child: Text(
            '${value.round()}K',
            textAlign: TextAlign.end,
            style: tokens.sensorStyle,
          ),
        ),
      ],
    );
  }

  void _apply(double kelvin) {
    ref
        .read(haServiceProvider)
        .turnOn(widget.entityId, {'color_temp_kelvin': kelvin.round()});
  }
}

/// A slider track painted as a warm→cool temperature gradient.
class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const _GradientTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    const gradient = LinearGradient(
      colors: [Color(0xFFFFB46B), Color(0xFFFFF4E0), Color(0xFFBFE0FF)],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    context.canvas.drawRRect(rrect, paint);
  }
}
