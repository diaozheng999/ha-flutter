import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/background/animated_sky_background.dart';
import 'package:ha_flutter/shared/background/static_gradient_background.dart';
import 'package:ha_flutter/shared/background/weather_animation_background.dart';
import 'package:ha_flutter/shared/util/performance_tier.dart';

/// Computed inputs that drive the sky: sun elevation, rising/setting, and the
/// current weather condition. Read once by whichever engine is active.
@immutable
class SkyInput {
  final double? elevation;
  final bool rising;
  final String condition;
  const SkyInput({
    required this.elevation,
    required this.rising,
    required this.condition,
  });
}

/// Resolved device performance tier (probed once, persisted).
final performanceTierProvider = FutureProvider<PerformanceTier>((ref) {
  return PerformanceTierProbe.resolve();
});

/// Debug override for the weather condition, letting all states be previewed
/// without waiting for real weather.
final debugForcedConditionProvider = StateProvider<String?>((ref) => null);

/// Live sky inputs derived from `sun.sun` and `weather.forecast_home`.
final skyInputProvider = Provider<SkyInput>((ref) {
  final sun = ref.watch(entityStateProvider(HaEntities.sun)).valueOrNull;
  final weather = ref.watch(entityStateProvider(HaEntities.weather)).valueOrNull;
  final forced = ref.watch(debugForcedConditionProvider);
  return SkyInput(
    elevation: sun?.attrDouble('elevation'),
    rising: sun?.attributes['rising'] == true,
    condition: forced ?? weather?.state ?? 'sunny',
  );
});

/// Marker base for the three background implementations. Each is the sole owner
/// of background rendering for its tier.
abstract class BackgroundEngine extends ConsumerWidget {
  /// Optional ambient tint injected as a middle gradient stop (room screens).
  final Color? ambientTint;
  const BackgroundEngine({super.key, this.ambientTint});
}

/// Selects and builds the correct [BackgroundEngine] for the resolved
/// [PerformanceTier]. Defaults to the medium engine while the tier probe runs.
class AppBackground extends ConsumerWidget {
  /// Optional ambient tint (room ambient lighting → middle gradient stop).
  final Color? ambientTint;
  const AppBackground({super.key, this.ambientTint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(performanceTierProvider).valueOrNull ??
        PerformanceTier.medium;
    return switch (tier) {
      PerformanceTier.low => StaticGradientBackground(ambientTint: ambientTint),
      PerformanceTier.medium =>
        AnimatedSkyBackground(ambientTint: ambientTint),
      PerformanceTier.high =>
        WeatherAnimationBackground(ambientTint: ambientTint),
    };
  }
}
