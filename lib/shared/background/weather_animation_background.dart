import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/background/sky_colors.dart';

/// High tier: muxes the sun-elevation gradient with a weather-condition colour
/// treatment and a [CustomPaint] particle layer (rain, clouds, haze mist,
/// stars). A lightning flash overlay fires randomly during storms.
///
/// Particle animation is driven by a single [Ticker] feeding a [ValueNotifier],
/// so only the painter repaints — never the gradient subtree. The ticker pauses
/// when the app is backgrounded.
class WeatherAnimationBackground extends ConsumerStatefulWidget {
  final Color? ambientTint;
  const WeatherAnimationBackground({super.key, this.ambientTint});

  @override
  ConsumerState<WeatherAnimationBackground> createState() =>
      _WeatherAnimationBackgroundState();
}

class _WeatherAnimationBackgroundState
    extends ConsumerState<WeatherAnimationBackground> {
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsed = ValueNotifier(0);
  final ValueNotifier<double> _flash = ValueNotifier(0);
  AppLifecycleListener? _lifecycle;

  double _lastLightningAt = -10;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((d) {
      final t = d.inMicroseconds / 1e6;
      _elapsed.value = t;
      _maybeLightning(t);
    })..start();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final active = state == AppLifecycleState.resumed;
        if (active && !_ticker.isActive) {
          _ticker.start();
        } else if (!active && _ticker.isActive) {
          _ticker.stop();
        }
      },
    );
  }

  void _maybeLightning(double t) {
    final condition = ref.read(skyInputProvider).condition;
    if (condition != 'lightning-rainy') return;
    if (t - _lastLightningAt < 8) return;
    // ~12% chance each second once eligible.
    if (_rng.nextDouble() < 0.12 / 60) {
      _lastLightningAt = t;
      _flash.value = 0.6 + _rng.nextDouble() * 0.3;
      final ms = 30 + _rng.nextInt(50);
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) _flash.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lifecycle?.dispose();
    _elapsed.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(skyInputProvider);
    final base = input.elevation != null
        ? SkyColors.forElevation(input.elevation!, rising: input.rising)
        : SkyColors.forTimeOfDay(DateTime.now());
    final sky = SkyColors.applyWeather(base, input.condition);
    final isNight = (input.elevation ?? 0) < -3;

    return Stack(
      fit: StackFit.expand,
      children: [
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: sky.top, end: sky.top),
          duration: const Duration(seconds: 20),
          builder: (context, top, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: SkyGradient(top!, sky.bottom)
                    .toLinearGradient(mid: widget.ambientTint),
              ),
            );
          },
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _WeatherParticlePainter(
              repaint: _elapsed,
              condition: input.condition,
              isNight: isNight,
            ),
            size: Size.infinite,
          ),
        ),
        // Lightning flash overlay.
        ValueListenableBuilder<double>(
          valueListenable: _flash,
          builder: (context, v, _) => v <= 0
              ? const SizedBox.shrink()
              : ColoredBox(
                  color: Colors.white.withValues(alpha: v * 0.5),
                ),
        ),
      ],
    );
  }
}

enum _ParticleKind { none, rain, pouring, clouds, partlyClouds, haze, stars }

class _WeatherParticlePainter extends CustomPainter {
  final ValueNotifier<double> elapsed;
  final String condition;
  final bool isNight;

  _WeatherParticlePainter({
    required ValueNotifier<double> repaint,
    required this.condition,
    required this.isNight,
  })  : elapsed = repaint,
        super(repaint: repaint);

  _ParticleKind get _kind {
    switch (condition) {
      case 'rainy':
        return _ParticleKind.rain;
      case 'pouring':
      case 'lightning-rainy':
        return _ParticleKind.pouring;
      case 'cloudy':
        return _ParticleKind.clouds;
      case 'partlycloudy':
        return _ParticleKind.partlyClouds;
      case 'fog':
      case 'haze':
      case 'hazy':
        return _ParticleKind.haze;
      case 'sunny':
      case 'clear-night':
        return isNight ? _ParticleKind.stars : _ParticleKind.none;
      default:
        return _ParticleKind.none;
    }
  }

  // Stable particle randomness so layout doesn't jitter between frames.
  static final _rng = math.Random(7);
  static final List<double> _rx = List.generate(220, (_) => _rng.nextDouble());
  static final List<double> _ry = List.generate(220, (_) => _rng.nextDouble());
  static final List<double> _rs = List.generate(220, (_) => _rng.nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsed.value;
    switch (_kind) {
      case _ParticleKind.rain:
        _paintRain(canvas, size, t, count: 90, opacity: 0.35);
        break;
      case _ParticleKind.pouring:
        _paintRain(canvas, size, t, count: 180, opacity: 0.5);
        _paintSplashes(canvas, size, t);
        break;
      case _ParticleKind.clouds:
        _paintClouds(canvas, size, t, count: 7, opacity: 0.18);
        break;
      case _ParticleKind.partlyClouds:
        _paintClouds(canvas, size, t, count: 3, opacity: 0.12);
        break;
      case _ParticleKind.haze:
        _paintMistBands(canvas, size, t);
        break;
      case _ParticleKind.stars:
        _paintStars(canvas, size, t);
        break;
      case _ParticleKind.none:
        break;
    }
  }

  void _paintRain(Canvas canvas, Size size, double t,
      {required int count, required double opacity}) {
    final paint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const angle = 60 * math.pi / 180;
    final dx = math.cos(angle) * 18;
    final dy = math.sin(angle) * 18;
    for (var i = 0; i < count; i++) {
      final speed = 0.6 + _rs[i] * 0.8;
      final y = ((t * speed + _ry[i]) % 1.0) * (size.height + 40) - 20;
      final x = (_rx[i] * size.width + t * 12) % size.width;
      canvas.drawLine(Offset(x, y), Offset(x - dx, y - dy), paint);
    }
  }

  void _paintSplashes(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = const Color(0x33B0C4DE);
    for (var i = 0; i < 40; i++) {
      final phase = (t * (1.5 + _rs[i]) + _rx[i]) % 1.0;
      if (phase > 0.15) continue;
      final x = _ry[i] * size.width;
      final r = phase / 0.15 * 4;
      canvas.drawCircle(
          Offset(x, size.height - 4), r, paint..style = PaintingStyle.stroke);
    }
  }

  void _paintClouds(Canvas canvas, Size size, double t,
      {required int count, required double opacity}) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    for (var i = 0; i < count; i++) {
      final drift = (t * (3 + _rs[i] * 2) + _rx[i] * size.width) %
          (size.width + 300) -
          150;
      final y = _ry[i] * size.height * 0.5;
      final w = 160 + _rs[i] * 180;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(drift, y), width: w, height: w * 0.5),
        paint,
      );
    }
  }

  void _paintMistBands(Canvas canvas, Size size, double t) {
    // Three horizontal mist bands at different depths drifting slowly.
    for (var band = 0; band < 3; band++) {
      final depth = band / 2.0;
      final paint = Paint()
        ..color = SkyColors.hazeTint.withValues(alpha: 0.10 + depth * 0.06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 + band * 10.0);
      final drift =
          (t * (4 + band * 3) % (size.width + 200)) - 100;
      final y = size.height * (0.3 + band * 0.22);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(drift, y),
          width: size.width * 1.4,
          height: 80 + band * 30,
        ),
        paint,
      );
    }
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 80; i++) {
      final twinkle =
          0.4 + 0.6 * (0.5 + 0.5 * math.sin((t * 0.5 + _rs[i] * 6.28)));
      paint.color = Colors.white.withValues(alpha: 0.8 * twinkle);
      final p = Offset(_rx[i] * size.width, _ry[i] * size.height * 0.7);
      canvas.drawCircle(p, 0.5 + _rs[i] * 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(_WeatherParticlePainter old) =>
      old.condition != condition || old.isNight != isNight;
}
