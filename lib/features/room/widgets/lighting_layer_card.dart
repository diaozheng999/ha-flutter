import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/models/room_lighting.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/capability_light_control.dart';

/// One lighting-role layer (overhead / task / ambient / …): the layer's
/// canonical control unit, with its member fixtures available on expansion.
///
/// Collapsed by default — the layer control is the thing you usually want, and
/// the members are the drill-down for when you don't.
class LightingLayerCard extends ConsumerStatefulWidget {
  final LightingLayer layer;

  const LightingLayerCard({super.key, required this.layer});

  @override
  ConsumerState<LightingLayerCard> createState() => _LightingLayerCardState();
}

class _LightingLayerCardState extends ConsumerState<LightingLayerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final layer = widget.layer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CapabilityLightControl(
          fixture: layer.unit,
          name: layer.displayName,
          trailingLeading: layer.isExpandable
              ? IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  visualDensity: VisualDensity.compact,
                  tooltip: _expanded
                      ? 'Hide individual lights'
                      : '${layer.members.length} individual lights',
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: tokens.offMuted,
                  ),
                )
              : null,
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final member in layer.members) ...[
                  CapabilityLightControl(fixture: member),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
