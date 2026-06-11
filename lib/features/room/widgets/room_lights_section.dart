import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/config/ha_entities.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/widgets/brightness_slider.dart';
import 'package:ha_flutter/shared/widgets/color_temperature_slider.dart';
import 'package:ha_flutter/shared/widgets/glass_card.dart';
import 'package:ha_flutter/shared/widgets/light_toggle_widget.dart';

/// Lights section for a room: group toggle, brightness, colour temperature, and
/// an expandable list of individual lights.
class RoomLightsSection extends ConsumerStatefulWidget {
  final RoomConfig room;
  const RoomLightsSection({super.key, required this.room});

  @override
  ConsumerState<RoomLightsSection> createState() => _RoomLightsSectionState();
}

class _RoomLightsSectionState extends ConsumerState<RoomLightsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final group = widget.room.lightGroup!;
    final individuals = widget.room.individualLights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        LightToggleWidget(entityId: group, name: 'All ${widget.room.name} lights'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              BrightnessSlider(entityId: group),
              ColorTemperatureSlider(entityId: group),
            ],
          ),
        ),
        if (individuals.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _expanded ? 'Hide individual lights' : 'Show individual lights',
              style: TextStyle(color: tokens.offMuted),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                for (final id in individuals) ...[
                  LightToggleWidget(entityId: id),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ],
    );
  }
}
