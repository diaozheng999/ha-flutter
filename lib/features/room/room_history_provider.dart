// 24-hour environment history for the Climate & Air trend graph, fetched via
// the REST history API and cached for 5 minutes per room.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/room_registry_provider.dart';

typedef TrendPoint = ({DateTime time, double value});

enum TrendKind { temperature, humidity, pm25 }

class TrendSeries {
  final TrendKind kind;
  final String label;
  final List<TrendPoint> points;

  const TrendSeries({
    required this.kind,
    required this.label,
    required this.points,
  });
}

/// History series for a room's environment sensors. Series whose fetch fails
/// or has fewer than two points are dropped silently — the graph simply
/// renders without them.
final roomHistoryProvider = FutureProvider.autoDispose
    .family<List<TrendSeries>, String>((ref, roomId) async {
  // Keep the result alive for 5 minutes after the last listener detaches so
  // section re-entry within that window skips the refetch.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final room = ref.watch(roomConfigProvider(roomId));
  final rest = ref.watch(haRestClientProvider);
  if (room == null) return const [];

  final sources = <(TrendKind, String, String)>[
    if (room.temperatureSensor != null)
      (TrendKind.temperature, 'Temperature', room.temperatureSensor!),
    if (room.humiditySensor != null)
      (TrendKind.humidity, 'Humidity', room.humiditySensor!),
    if (room.pm25Sensor != null) (TrendKind.pm25, 'PM2.5', room.pm25Sensor!),
  ];

  final results = await Future.wait([
    for (final (_, _, id) in sources)
      rest
          .fetchHistory(id, hours: 24)
          .catchError((_) => const <TrendPoint>[]),
  ]);

  return [
    for (var i = 0; i < sources.length; i++)
      if (results[i].length >= 2)
        TrendSeries(
          kind: sources[i].$1,
          label: sources[i].$2,
          points: results[i],
        ),
  ];
});
