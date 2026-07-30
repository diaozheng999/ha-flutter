import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';

/// Hue + saturation picker for colour-capable lights. Shown only when the
/// fixture advertises a colour mode.
///
/// Sends `hs_color`, which Home Assistant converts to whatever the light
/// natively speaks (xy for Hue, rgb for Yeelight), so one control serves every
/// colour bulb. Calls are debounced at 200 ms like the other light sliders.
class LightColorPicker extends ConsumerStatefulWidget {
  final String entityId;
  const LightColorPicker({super.key, required this.entityId});

  @override
  ConsumerState<LightColorPicker> createState() => _LightColorPickerState();
}

class _LightColorPickerState extends ConsumerState<LightColorPicker> {
  final _debouncer = Debouncer();
  double? _dragHue;
  double? _dragSaturation;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    final hs = state?.hsColor;

    final hue = _dragHue ?? hs?.hue ?? 0;
    final saturation = _dragSaturation ?? hs?.saturation ?? 100;

    final swatch =
        HSVColor.fromAHSV(1, hue % 360, (saturation / 100).clamp(0, 1), 1)
            .toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatch,
                border: Border.all(color: tokens.glassBorder),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  trackShape: const _HueTrackShape(),
                ),
                child: Slider(
                  value: hue.clamp(0, 360),
                  max: 360,
                  label: '${hue.round()}°',
                  onChanged: (v) {
                    setState(() => _dragHue = v);
                    _debouncer.call(() => _apply(v, saturation));
                  },
                  onChangeEnd: (v) {
                    _apply(v, saturation);
                    setState(() => _dragHue = null);
                  },
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${hue.round()}°',
                textAlign: TextAlign.end,
                style: tokens.sensorStyle,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.opacity_outlined, size: 20, color: tokens.offMuted),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  trackShape: _SaturationTrackShape(hue % 360),
                ),
                child: Slider(
                  value: saturation.clamp(0, 100),
                  max: 100,
                  label: '${saturation.round()}%',
                  onChanged: (v) {
                    setState(() => _dragSaturation = v);
                    _debouncer.call(() => _apply(hue, v));
                  },
                  onChangeEnd: (v) {
                    _apply(hue, v);
                    setState(() => _dragSaturation = null);
                  },
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${saturation.round()}%',
                textAlign: TextAlign.end,
                style: tokens.sensorStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _apply(double hue, double saturation) {
    ref.read(haServiceProvider).turnOn(widget.entityId, {
      'hs_color': [hue.clamp(0, 360).roundToDouble(), saturation.clamp(0, 100).roundToDouble()],
    });
  }
}

/// Full-spectrum hue track.
class _HueTrackShape extends RoundedRectSliderTrackShape {
  const _HueTrackShape();

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
    final gradient = LinearGradient(
      colors: [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h % 360, 1, 1).toColor(),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
  }
}

/// Saturation track, tinted by the currently selected hue.
class _SaturationTrackShape extends RoundedRectSliderTrackShape {
  final double hue;
  const _SaturationTrackShape(this.hue);

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
    final gradient = LinearGradient(
      colors: [
        HSVColor.fromAHSV(1, hue, 0, 1).toColor(),
        HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
  }
}
