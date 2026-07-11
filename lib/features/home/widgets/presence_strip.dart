import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';

/// Compact inline presence chips — one per resident, sized for a header row.
class PresenceStrip extends StatelessWidget {
  const PresenceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PersonDot(entityId: HaEntities.personSimon, name: 'Simon'),
        SizedBox(width: 6),
        _PersonDot(entityId: HaEntities.personYamin, name: 'Ya Min'),
      ],
    );
  }
}

/// Avatar initial + presence-coloured dot. Tap shows a tooltip with name/status.
class _PersonDot extends ConsumerWidget {
  final String entityId;
  final String name;
  const _PersonDot({required this.entityId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final value =
        ref.watch(entityStateProvider(entityId)).valueOrNull?.state ?? 'unknown';
    final (label, dot) = switch (value) {
      'home' => ('Home', tokens.severityNominal),
      'not_home' => ('Away', const Color(0xFF78909C)),
      _ => ('Unknown', tokens.severityWarning),
    };

    return Tooltip(
      message: '$name · $label',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: tokens.glassFill,
            child: Text(
              name.characters.first,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot,
                border: Border.all(color: Colors.black54, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
