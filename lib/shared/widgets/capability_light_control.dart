import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/ha/models/entity_state.dart';
import 'package:ha_flutter/ha/models/light_capabilities.dart';
import 'package:ha_flutter/ha/models/room_lighting.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:ha_flutter/shared/util/hs_color_converter.dart';
import 'package:ha_flutter/shared/util/mdi_resolver.dart';
import 'package:ha_flutter/shared/widgets/brightness_slider.dart';
import 'package:ha_flutter/shared/widgets/color_temperature_slider.dart';
import 'package:ha_flutter/shared/widgets/control_card.dart';
import 'package:ha_flutter/shared/widgets/light_color_picker.dart';
import 'package:ha_flutter/shared/widgets/light_effect_selector.dart';
import 'package:ha_flutter/shared/widgets/pending_overlay.dart';
import 'package:ha_flutter/shared/widgets/power_toggle.dart';

/// The single lighting control primitive: renders exactly the rungs a fixture
/// advertises and nothing more.
///
/// One widget serves the whole heterogeneous fleet — a binary bulb or a
/// role-labelled wall switch gets only a power toggle, a tunable-white bulb adds
/// brightness and colour temperature, an RGBW bulb adds colour and effects.
/// Colour and effects sit behind a disclosure so the common case stays quiet.
///
/// A group fixture applies every change to the group entity, letting HA fan the
/// change out to whichever members support it — the union in
/// `supported_color_modes` is HA's, never recomputed here.
class CapabilityLightControl extends ConsumerStatefulWidget {
  final LightingFixture fixture;

  /// Overrides the header name (e.g. a layer's display name).
  final String? name;

  /// Extra trailing header widget placed before the power toggle, used by
  /// layer cards for their expand affordance.
  final Widget? trailingLeading;

  const CapabilityLightControl({
    super.key,
    required this.fixture,
    this.name,
    this.trailingLeading,
  });

  @override
  ConsumerState<CapabilityLightControl> createState() =>
      _CapabilityLightControlState();
}

class _CapabilityLightControlState
    extends ConsumerState<CapabilityLightControl> {
  bool _expressionOpen = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fixture = widget.fixture;
    final entityId = fixture.entityId;
    final state = ref.watch(entityStateProvider(entityId)).valueOrNull;

    final isOn = state?.isOn ?? false;
    final unavailable = state?.isUnavailable ?? false;

    // Capabilities track live state so a fixture that reports late still gets
    // its full control set once state arrives.
    final caps = state == null
        ? fixture.capabilities
        : LightCapabilities.fromState(
            state,
            colorTempSteps: fixture.capabilities.colorTempSteps,
          );

    final service = ref.read(haServiceProvider);
    final hasExpression = caps.supports(LightRung.color) ||
        caps.supports(LightRung.effects);

    final body = <Widget>[
      if (caps.supports(LightRung.brightness))
        BrightnessSlider(entityId: entityId),
      if (caps.supports(LightRung.colorTemp))
        ColorTemperatureSlider(
          entityId: entityId,
          steps: caps.colorTempSteps,
        ),
      if (hasExpression) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _expressionOpen = !_expressionOpen),
            icon: Icon(
              _expressionOpen ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(
              _expressionOpen ? 'Less' : 'Colour & effects',
              style: TextStyle(color: tokens.offMuted, fontSize: 12),
            ),
          ),
        ),
        if (_expressionOpen) ...[
          if (caps.supports(LightRung.color))
            LightColorPicker(entityId: entityId),
          if (caps.supports(LightRung.effects))
            LightEffectSelector(
              entityId: entityId,
              effects: caps.effects,
            ),
        ],
      ],
    ];

    return PendingOverlay(
      entityId: entityId,
      child: ControlCard(
        icon: mdiIcon(state?.icon, fallback: domainFallback(fixture.domain)),
        name: widget.name ?? fixture.name,
        status: _statusLine(caps, state, isOn, unavailable),
        isOn: isOn,
        unavailable: unavailable,
        glowColor: isOn && state != null ? HsColorConverter.glowFor(state) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?widget.trailingLeading,
            PowerToggle(
              isOn: isOn,
              onTap: unavailable
                  ? null
                  : () =>
                      isOn ? service.turnOff(entityId) : service.turnOn(entityId),
            ),
          ],
        ),
        body: body.isEmpty
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: body,
              ),
      ),
    );
  }

  /// One line describing what the fixture is doing now. On/off-only fixtures
  /// have nothing to add beyond their power state.
  String _statusLine(
    LightCapabilities caps,
    EntityState? state,
    bool isOn,
    bool unavailable,
  ) {
    if (unavailable) return 'Unavailable';
    if (!isOn) return 'Off';
    if (caps.isOnOffOnly) return 'On';

    final parts = <String>[];
    final brightness = state?.attrInt('brightness');
    if (caps.supports(LightRung.brightness) && brightness != null) {
      parts.add('${(brightness / 255 * 100).round()}%');
    }
    final kelvin = state?.attrInt('color_temp_kelvin');
    if (caps.supports(LightRung.colorTemp) && kelvin != null) {
      parts.add('${kelvin}K');
    }
    final effect = state?.attrString('effect');
    if (effect != null && effect.isNotEmpty && effect.toLowerCase() != 'none') {
      parts.add(effect);
    }
    return parts.isEmpty ? 'On' : parts.join(' · ');
  }
}
