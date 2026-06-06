import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/home/widgets/presence_strip.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Greeting header: large clock, date, weather summary, and a time-of-day
/// greeting. The clock ticks once a minute without rebuilding the whole screen.
class GreetingHeader extends ConsumerStatefulWidget {
  const GreetingHeader({super.key});

  @override
  ConsumerState<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends ConsumerState<GreetingHeader> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final weather = ref.watch(entityStateProvider(HaEntities.weather)).valueOrNull;
    final temp = weather?.attrDouble('temperature');

    final weatherCondition = weather != null ? _weatherLabel(weather.state) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_two(_now.hour)}:${_two(_now.minute)}',
                style: tokens.sensorStyle.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_greeting · ${_weekday(_now.weekday)}, ${_now.day} ${_month(_now.month)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.offMuted),
              ),
              if (weather != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(_weatherIcon(weather.state),
                        size: 16, color: tokens.onAccent),
                    const SizedBox(width: 4),
                    Text(
                      [
                        weatherCondition,
                        if (temp != null) '${temp.toStringAsFixed(0)}°',
                      ].nonNulls.join('  '),
                      style: TextStyle(
                          fontSize: 13,
                          color: tokens.offMuted.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: PresenceStrip(),
        ),
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _weekday(int w) => const [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ][w - 1];

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  static String _weatherLabel(String condition) => switch (condition) {
        'sunny' => 'Sunny',
        'clear-night' => 'Clear',
        'partlycloudy' => 'Partly cloudy',
        'cloudy' => 'Cloudy',
        'rainy' => 'Rainy',
        'pouring' => 'Heavy rain',
        'lightning-rainy' => 'Thunderstorm',
        'fog' || 'hazy' || 'haze' => 'Foggy',
        'windy' => 'Windy',
        _ => condition,
      };

  static IconData _weatherIcon(String condition) => switch (condition) {
        'sunny' => Icons.wb_sunny_outlined,
        'clear-night' => Icons.nightlight_outlined,
        'partlycloudy' => Icons.wb_cloudy_outlined,
        'cloudy' => Icons.cloud_outlined,
        'rainy' => Icons.water_drop_outlined,
        'pouring' => Icons.grain,
        'lightning-rainy' => Icons.thunderstorm_outlined,
        'fog' || 'hazy' || 'haze' => Icons.foggy,
        'windy' => Icons.air,
        _ => Icons.wb_cloudy_outlined,
      };
}
