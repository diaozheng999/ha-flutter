import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
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

    return Column(
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
        Row(
          children: [
            Text(
              '$_greeting · ${_weekday(_now.weekday)}, ${_now.day} ${_month(_now.month)}',
              style: TextStyle(color: tokens.offMuted),
            ),
            const Spacer(),
            if (weather != null) ...[
              Icon(_weatherIcon(weather.state), size: 18, color: tokens.onAccent),
              const SizedBox(width: 4),
              Text(
                temp != null ? '${temp.toStringAsFixed(0)}°' : weather.state,
                style: tokens.sensorStyle,
              ),
            ],
          ],
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
