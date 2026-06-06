import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Shows Shiny's last-known floor map with a manual refresh and a state label.
class VacuumMap extends ConsumerStatefulWidget {
  const VacuumMap({super.key});

  @override
  ConsumerState<VacuumMap> createState() => _VacuumMapState();
}

class _VacuumMapState extends ConsumerState<VacuumMap> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final url = await ref
        .read(haRestClientProvider)
        .proxyImageUrl('/api/image_proxy/${HaEntities.vacuumMap}',
            cacheBust: true);
    if (mounted) setState(() => _url = url.toString());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(HaEntities.vacuum)).valueOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined),
              const SizedBox(width: 8),
              const Text('Shiny Map',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: _url == null
                  ? const ColoredBox(color: Colors.black)
                  : Image.network(
                      _url!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Text('Map unavailable',
                              style: TextStyle(color: tokens.offMuted)),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stateLabel(state?.state ?? 'unknown'),
            style: TextStyle(color: tokens.offMuted),
          ),
        ],
      ),
    );
  }

  String _stateLabel(String s) => switch (s) {
        'docked' => 'Docked',
        'cleaning' => 'Cleaning',
        'returning' => 'Returning',
        'paused' => 'Paused',
        'idle' => 'Idle',
        _ => 'Unknown',
      };
}
