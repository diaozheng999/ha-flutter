import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/features/app_shell.dart';
import 'package:ha_flutter/features/security/widgets/camera_view.dart';
import 'package:ha_flutter/features/security/widgets/frigate_thumbnails.dart';
import 'package:ha_flutter/features/security/widgets/ptz_controls.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/connection_chip.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';

/// Security tab: alarm status, doorbell + living room camera feeds with PTZ,
/// and recent Frigate event thumbnails.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Index 2 == Security; feeds pause when this tab is not active.
    final active = ref.watch(activeTabProvider) == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        actions: const [ConnectionChip()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _AlarmChip(),
            const SizedBox(height: 16),
            const _SectionLabel('Front Door'),
            const SizedBox(height: 8),
            CameraView(entityId: HaEntities.doorbellCamera, active: active),
            const SizedBox(height: 16),
            const _SectionLabel('Living Room'),
            const SizedBox(height: 8),
            CameraView(entityId: HaEntities.livingRoomCamera, active: active),
            const SizedBox(height: 12),
            const PtzControls(),
            const SizedBox(height: 16),
            const _SectionLabel('Recent Events'),
            const SizedBox(height: 8),
            const FrigateThumbnails(),
          ],
        ),
      ),
    );
  }
}

class _AlarmChip extends ConsumerStatefulWidget {
  const _AlarmChip();

  @override
  ConsumerState<_AlarmChip> createState() => _AlarmChipState();
}

class _AlarmChipState extends ConsumerState<_AlarmChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entityStateProvider(HaEntities.alarm)).valueOrNull;
    final value = state?.state ?? 'unknown';
    final (label, color, triggered) = switch (value) {
      'disarmed' => ('Disarmed', const Color(0xFF66BB6A), false),
      'armed_home' => ('Armed Home', const Color(0xFFFFB300), false),
      'armed_away' => ('Armed Away', const Color(0xFFEF5350), false),
      'triggered' => ('Triggered', const Color(0xFFEF5350), true),
      _ => ('Unknown', context.tokens.offMuted, false),
    };

    final card = GlassCard(
      glowColor: triggered ? color : null,
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color),
          const SizedBox(width: 12),
          Text('Alarm', style: TextStyle(color: context.tokens.offMuted)),
          const Spacer(),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );

    if (!triggered) return card;
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_pulse),
      child: card,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
}
