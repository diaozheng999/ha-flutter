import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';

/// A glassmorphic on/off light tile that glows in the light's own colour when
/// on. Unavailable lights render dimmed and non-interactive.
class LightToggleWidget extends ConsumerWidget {
  final String entityId;
  final String? name;

  const LightToggleWidget({
    super.key,
    required this.entityId,
    this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final asyncState = ref.watch(entityStateProvider(entityId));
    final state = asyncState.valueOrNull;
    final isOn = state?.isOn ?? false;
    final unavailable = state?.isUnavailable ?? false;
    final label = name ?? state?.friendlyName ?? entityId;

    return PendingOverlay(
      entityId: entityId,
      child: GlassCard(
        glowColor: isOn ? HsColorConverter.glowFor(state!) : null,
        dimmed: unavailable,
        onTap:
            unavailable ? null : () => ref.read(haServiceProvider).toggle(entityId),
        child: Row(
          children: [
            Icon(
              mdiIcon(state?.icon, fallback: domainFallback('light')),
              color: isOn ? tokens.onAccent : tokens.offMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    unavailable
                        ? 'Unavailable'
                        : isOn
                            ? 'On'
                            : 'Off',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.offMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
