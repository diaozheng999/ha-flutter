import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/background/sky_colors.dart';

/// A [Tween] over [SkyGradient] so gradient transitions can be driven by the
/// implicit animation machinery.
class _SkyGradientTween extends Tween<SkyGradient> {
  _SkyGradientTween({super.begin, super.end});
  @override
  SkyGradient lerp(double t) => SkyGradient.lerp(begin!, end!, t);
}

/// Medium tier: a gradient that smoothly tracks sun elevation, plus a twinkling
/// star scatter at night. One repeating controller drives the twinkle.
class AnimatedSkyBackground extends ConsumerStatefulWidget {
  final Color? ambientTint;
  const AnimatedSkyBackground({super.key, this.ambientTint});

  @override
  ConsumerState<AnimatedSkyBackground> createState() =>
      _AnimatedSkyBackgroundState();
}

class _AnimatedSkyBackgroundState extends ConsumerState<AnimatedSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(skyInputProvider);
    final elevation = input.elevation;
    final sky = elevation != null
        ? SkyColors.forElevation(elevation, rising: input.rising)
        : SkyColors.forTimeOfDay(DateTime.now());

    // Stars fade in as the sun sinks below civil twilight.
    final starOpacity = elevation == null
        ? 0.0
        : ((-elevation - 3) / 9).clamp(0.0, 1.0);

    return TweenAnimationBuilder<SkyGradient>(
      tween: _SkyGradientTween(begin: sky, end: sky),
      duration: const Duration(seconds: 30),
      builder: (context, value, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: value.toLinearGradient(mid: widget.ambientTint),
          ),
          child: starOpacity <= 0.01
              ? const SizedBox.expand()
              : AnimatedBuilder(
                  animation: _twinkle,
                  builder: (context, _) => CustomPaint(
                    painter: _StarPainter(
                      phase: _twinkle.value,
                      opacity: starOpacity,
                    ),
                    size: Size.infinite,
                  ),
                ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final double phase;
  final double opacity;
  static const _count = 80;
  static final _rng = math.Random(42); // fixed seed → stable star field
  static final List<Offset> _positions = List.generate(
    _count,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<double> _phaseOffsets =
      List.generate(_count, (_) => _rng.nextDouble());
  static final List<double> _sizes =
      List.generate(_count, (_) => 0.5 + _rng.nextDouble() * 1.3);

  _StarPainter({required this.phase, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < _count; i++) {
      final twinkle =
          0.4 + 0.6 * (0.5 + 0.5 * math.sin((phase + _phaseOffsets[i]) * math.pi * 2));
      paint.color = Colors.white.withValues(alpha: opacity * twinkle);
      final p = Offset(
        _positions[i].dx * size.width,
        _positions[i].dy * size.height * 0.7, // cluster toward the top
      );
      canvas.drawCircle(p, _sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.phase != phase || old.opacity != opacity;
}
