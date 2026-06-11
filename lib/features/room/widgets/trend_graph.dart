import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/room/room_history_provider.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Non-interactive 24 h environment trend chart for a room. Renders nothing
/// while loading, on fetch failure, or when no series has data, so the climate
/// controls above are never blocked on history.
class TrendGraph extends ConsumerWidget {
  final String roomId;
  const TrendGraph({super.key, required this.roomId});

  static const _seriesColors = {
    TrendKind.temperature: Color(0xFFFFD27D),
    TrendKind.humidity: Color(0xFF64B5F6),
    TrendKind.pm25: Color(0xFF81C784),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final series = ref.watch(roomHistoryProvider(roomId)).valueOrNull;
    if (series == null || series.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Last 24 hours',
                  style: TextStyle(fontSize: 12, color: tokens.offMuted)),
              const Spacer(),
              for (final s in series) ...[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 12, right: 4),
                  decoration: BoxDecoration(
                    color: _seriesColors[s.kind],
                    shape: BoxShape.circle,
                  ),
                ),
                Text(s.label,
                    style: TextStyle(fontSize: 12, color: tokens.offMuted)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                series: series,
                colors: _seriesColors,
                gridColor: tokens.glassBorder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendSeries> series;
  final Map<TrendKind, Color> colors;
  final Color gridColor;

  _TrendPainter({
    required this.series,
    required this.colors,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Faint horizontal gridlines at quarters.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Common 24 h x-axis ending now.
    final end = DateTime.now();
    final start = end.subtract(const Duration(hours: 24));
    final spanMs = end.difference(start).inMilliseconds.toDouble();

    for (final s in series) {
      // Each series normalises to its own min/max (units differ).
      final values = s.points.map((p) => p.value);
      final minV = values.reduce((a, b) => a < b ? a : b);
      final maxV = values.reduce((a, b) => a > b ? a : b);
      final range = (maxV - minV).abs() < 0.5 ? 1.0 : (maxV - minV);

      Offset toOffset(TrendPoint p) {
        final x = (p.time.difference(start).inMilliseconds / spanMs)
                .clamp(0.0, 1.0) *
            size.width;
        final y = size.height -
            ((p.value - minV) / range) * (size.height - 8) -
            4;
        return Offset(x, y);
      }

      final color = colors[s.kind] ?? gridColor;
      final path = Path()..moveTo(toOffset(s.points.first).dx, toOffset(s.points.first).dy);
      for (final p in s.points.skip(1)) {
        final o = toOffset(p);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.series != series;
}
