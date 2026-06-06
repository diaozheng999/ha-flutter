import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// DB cabinet monitor: live temperature + fan speed, plus a 24-hour temperature
/// line chart fetched from the REST history endpoint (manual refresh only).
class DbCabinet extends ConsumerStatefulWidget {
  const DbCabinet({super.key});

  @override
  ConsumerState<DbCabinet> createState() => _DbCabinetState();
}

class _DbCabinetState extends ConsumerState<DbCabinet> {
  List<({DateTime time, double value})>? _history;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final points = await ref
          .read(haRestClientProvider)
          .fetchHistory(HaEntities.dbCabinetTemp, hours: 24);
      if (mounted) setState(() => _history = points);
    } catch (_) {
      if (mounted) setState(() => _history = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final temp =
        ref.watch(entityStateProvider(HaEntities.dbCabinetTemp)).valueOrNull;
    final fan =
        ref.watch(entityStateProvider(HaEntities.dbCabinetFanSpeed)).valueOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_outlined),
              const SizedBox(width: 8),
              const Text('DB Cabinet',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Row(
            children: [
              _reading(tokens, Icons.thermostat,
                  temp != null ? '${temp.state}°C' : '—'),
              const SizedBox(width: 24),
              _reading(tokens, Icons.air,
                  fan != null ? '${fan.state} RPM' : '—'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_history == null || _history!.length < 2)
                    ? Center(
                        child: Text('No history',
                            style: TextStyle(color: tokens.offMuted)))
                    : CustomPaint(
                        painter: _LineChartPainter(
                          _history!,
                          tokens.onAccent,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _reading(AppTokens tokens, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: tokens.offMuted),
          const SizedBox(width: 6),
          Text(text, style: tokens.sensorStyle.copyWith(fontSize: 18)),
        ],
      );
}

class _LineChartPainter extends CustomPainter {
  final List<({DateTime time, double value})> points;
  final Color color;
  _LineChartPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.5 ? 1.0 : (maxV - minV);
    final t0 = points.first.time.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.time.millisecondsSinceEpoch.toDouble();
    final span = (t1 - t0).abs() < 1 ? 1.0 : (t1 - t0);

    Offset toOffset(({DateTime time, double value}) p) {
      final x = (p.time.millisecondsSinceEpoch - t0) / span * size.width;
      final y = size.height - ((p.value - minV) / range) * size.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(0, toOffset(points.first).dy);
    for (final p in points) {
      final o = toOffset(p);
      path.lineTo(o.dx, o.dy);
    }

    // Fill under the line.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.points != points;
}
