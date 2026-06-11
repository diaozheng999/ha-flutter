import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/shared/background/background_engine.dart';
import 'package:ha_flutter/shared/background/sky_colors.dart';

/// Low tier: a single static gradient derived from the current time of day.
/// No animation, no sun/weather subscription — zero per-frame cost.
class StaticGradientBackground extends BackgroundEngine {
  const StaticGradientBackground({super.key, super.ambientTint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sky = SkyColors.forTimeOfDay(DateTime.now());
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: sky.toLinearGradient(mid: ambientTint),
      ),
      child: const SizedBox.expand(),
    );
  }
}
