import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rendering capability tier that selects which background engine runs.
enum PerformanceTier { low, medium, high }

/// Resolves the device's [PerformanceTier] once and persists it. The first
/// launch runs a short frame-timing probe; later launches read the cached
/// result so the engine choice is stable.
///
/// Pass `--dart-define=PERFORMANCE_TIER=low|medium|high` at launch to force a
/// specific tier for debugging, bypassing both the cache and the probe.
class PerformanceTierProbe {
  static const _prefsKey = 'performance_tier';

  // Compile-time override: flutter run --dart-define=PERFORMANCE_TIER=low
  static const _dartDefine = String.fromEnvironment('PERFORMANCE_TIER');

  /// Returns the persisted tier, or runs a probe and persists the result.
  ///
  /// If `--dart-define=PERFORMANCE_TIER=<tier>` was supplied at build/run time,
  /// that value is returned immediately without touching shared preferences.
  static Future<PerformanceTier> resolve() async {
    if (_dartDefine.isNotEmpty) {
      return PerformanceTier.values.firstWhere(
        (t) => t.name == _dartDefine.toLowerCase(),
        orElse: () => PerformanceTier.medium,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      return PerformanceTier.values.firstWhere(
        (t) => t.name == cached,
        orElse: () => PerformanceTier.medium,
      );
    }
    final tier = await _probe();
    await prefs.setString(_prefsKey, tier.name);
    return tier;
  }

  /// Forces a tier (debug/testing) and persists it.
  static Future<void> override(PerformanceTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tier.name);
  }

  /// Samples frame build+raster durations over a short window and classifies
  /// the device. Devices that comfortably hold the 16.6 ms budget qualify for
  /// the high tier; sluggish ones drop to low.
  static Future<PerformanceTier> _probe() async {
    final durations = <double>[];
    final completer = Completer<void>();

    void callback(List<FrameTiming> timings) {
      for (final t in timings) {
        final total = t.totalSpan.inMicroseconds / 1000.0; // ms
        durations.add(total);
      }
      if (durations.length >= 30 && !completer.isCompleted) {
        completer.complete();
      }
    }

    SchedulerBinding.instance.addTimingsCallback(callback);
    // Bound the probe so a stalled device still resolves.
    Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    SchedulerBinding.instance.removeTimingsCallback(callback);

    if (durations.isEmpty) return PerformanceTier.medium;
    durations.sort();
    // 90th-percentile frame time is a good worst-case signal.
    final p90 = durations[(durations.length * 0.9).floor().clamp(
      0,
      durations.length - 1,
    )];

    if (p90 <= 16.6) return PerformanceTier.high;
    if (p90 <= 28.0) return PerformanceTier.medium;
    return PerformanceTier.low;
  }
}
