import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/debouncer.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';

/// Compact light tile for grid placement: name, tap-to-toggle, and an inline
/// brightness slider. Glows in the light's colour when on; unavailable lights
/// render dimmed and non-interactive. Slider calls are debounced at 200 ms and
/// dragging to 0 turns the light off.
class LightTile extends ConsumerStatefulWidget {
  final String entityId;
  final String? name;

  const LightTile({super.key, required this.entityId, this.name});

  @override
  ConsumerState<LightTile> createState() => _LightTileState();
}

class _LightTileState extends ConsumerState<LightTile> {
  final _debouncer = Debouncer();
  double? _dragValue;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _apply(double pct) {
    final service = ref.read(haServiceProvider);
    if (pct <= 0) {
      service.turnOff(widget.entityId);
    } else {
      service.turnOn(widget.entityId, {'brightness_pct': pct.round()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(widget.entityId)).valueOrNull;
    final isOn = state?.isOn ?? false;
    final unavailable = state?.isUnavailable ?? false;
    final label = widget.name ?? state?.friendlyName ?? widget.entityId;

    final colorModes =
        state?.attrList<String>('supported_color_modes') ?? const [];
    final dimmable = colorModes.any((m) => m != 'onoff');

    final brightness = state?.attrInt('brightness') ?? 0;
    final livePct =
        isOn ? (brightness / 255 * 100).clamp(0, 100).toDouble() : 0.0;
    final pct = _dragValue ?? livePct;

    return PendingOverlay(
      entityId: widget.entityId,
      child: GlassCard(
        glowColor: isOn ? HsColorConverter.glowFor(state!) : null,
        dimmed: unavailable,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        onTap: unavailable
            ? null
            : () {
                final service = ref.read(haServiceProvider);
                isOn
                    ? service.turnOff(widget.entityId)
                    : service.turnOn(widget.entityId);
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mdiIcon(state?.icon, fallback: domainFallback('light')),
                  size: 20,
                  color: isOn ? tokens.onAccent : tokens.offMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Text(
              unavailable
                  ? 'Unavailable'
                  : isOn
                      ? '${pct.round()}%'
                      : 'Off',
              style: TextStyle(fontSize: 11, color: tokens.offMuted),
            ),
            if (dimmable)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: pct,
                  max: 100,
                  onChanged: unavailable
                      ? null
                      : (v) {
                          setState(() => _dragValue = v);
                          _debouncer.call(() => _apply(v));
                        },
                  onChangeEnd: (v) {
                    _apply(v);
                    setState(() => _dragValue = null);
                  },
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
