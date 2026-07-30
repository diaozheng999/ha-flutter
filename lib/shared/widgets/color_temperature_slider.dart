import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';

/// Colour-temperature slider over a warm→cool gradient track. Renders only when
/// the light supports `color_temp`. Service calls are debounced at 200 ms.
///
/// When [steps] is non-empty the fixture accepts only those kelvin values, so
/// the track snaps between them instead of sweeping continuously. HA cannot
/// advertise discreteness, so the steps come from configuration (D19).
class ColorTemperatureSlider extends ConsumerStatefulWidget {
  final String entityId;

  /// Discrete kelvin values this fixture accepts. Empty = continuous range.
  final List<int> steps;

  const ColorTemperatureSlider({
    super.key,
    required this.entityId,
    this.steps = const [],
  });

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

    final steps = widget.steps;
    if (steps.isNotEmpty) return _buildStepped(context, state, steps);

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

  /// Discrete variant: the track snaps between the accepted kelvin values, so a
  /// stepped fixture cannot be dragged to a temperature it would silently
  /// round away.
  Widget _buildStepped(
    BuildContext context,
    EntityState state,
    List<int> steps,
  ) {
    final tokens = context.tokens;
    final sorted = [...steps]..sort();
    final current = state.attrInt('color_temp_kelvin');
    final index = _dragValue?.round() ?? _nearestIndex(sorted, current);
    final kelvin = sorted[index.clamp(0, sorted.length - 1)];

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
              value: index.toDouble(),
              min: 0,
              max: (sorted.length - 1).toDouble(),
              divisions: sorted.length - 1,
              label: '${kelvin}K',
              onChanged: (v) {
                setState(() => _dragValue = v);
                _debouncer.call(() => _applyKelvin(sorted[v.round()]));
              },
              onChangeEnd: (v) {
                _applyKelvin(sorted[v.round()]);
                setState(() => _dragValue = null);
              },
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '${kelvin}K',
            textAlign: TextAlign.end,
            style: tokens.sensorStyle,
          ),
        ),
      ],
    );
  }

  static int _nearestIndex(List<int> sorted, int? kelvin) {
    if (kelvin == null) return 0;
    var best = 0;
    var bestDelta = (sorted.first - kelvin).abs();
    for (var i = 1; i < sorted.length; i++) {
      final delta = (sorted[i] - kelvin).abs();
      if (delta < bestDelta) {
        best = i;
        bestDelta = delta;
      }
    }
    return best;
  }

  void _apply(double kelvin) => _applyKelvin(kelvin.round());

  void _applyKelvin(int kelvin) {
    ref
        .read(haServiceProvider)
        .turnOn(widget.entityId, {'color_temp_kelvin': kelvin});
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
