import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Horizontal strip of resident presence chips.
class PresenceStrip extends StatelessWidget {
  const PresenceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _PersonChip(entityId: HaEntities.personSimon, name: 'Simon')),
        SizedBox(width: 12),
        Expanded(child: _PersonChip(entityId: HaEntities.personYamin, name: 'Ya Min')),
      ],
    );
  }
}

class _PersonChip extends ConsumerWidget {
  final String entityId;
  final String name;
  const _PersonChip({required this.entityId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;
    final value = state?.state ?? 'unknown';
    final (label, dot, filled) = switch (value) {
      'home' => ('Home', const Color(0xFF66BB6A), true),
      'not_home' => ('Away', tokens.offMuted, false),
      _ => ('Unknown', const Color(0xFFFFB300), false),
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tokens.glassFill,
            child: Text(name.characters.first),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(label, style: TextStyle(fontSize: 12, color: tokens.offMuted)),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? dot : Colors.transparent,
              border: Border.all(color: dot, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
