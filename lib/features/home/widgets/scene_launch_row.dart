import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/features/scenes/scenes_providers.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Horizontally scrolling row of scene tiles. Tapping activates the scene and
/// flashes a confirmation checkmark.
class SceneLaunchRow extends ConsumerWidget {
  const SceneLaunchRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider);
    return scenes.when(
      loading: () => const SizedBox(height: 88),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SceneTile(
              entityId: list[i].entityId,
              name: list[i].friendlyName,
            ),
          ),
        );
      },
    );
  }
}

class SceneTile extends ConsumerStatefulWidget {
  final String entityId;
  final String name;
  const SceneTile({super.key, required this.entityId, required this.name});

  @override
  ConsumerState<SceneTile> createState() => _SceneTileState();
}

class _SceneTileState extends ConsumerState<SceneTile> {
  bool _confirming = false;

  Future<void> _activate() async {
    await ref.read(haServiceProvider).call(
      'scene',
      'turn_on',
      data: {'entity_id': widget.entityId},
    );
    if (!mounted) return;
    setState(() => _confirming = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 120,
      child: GlassCard(
        onTap: _activate,
        glowColor: _confirming ? const Color(0xFF66BB6A) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _confirming ? Icons.check_circle : Icons.auto_awesome,
              color: _confirming ? const Color(0xFF66BB6A) : tokens.onAccent,
            ),
            const SizedBox(height: 8),
            Text(
              widget.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
