import 'package:ha_flutter/ha/models/entity_state.dart';

/// One rung of the lighting capability ladder. A fixture supports a contiguous
/// prefix in spirit but not in guarantee — e.g. an RGB-only bulb has [color]
/// without [colorTemp] — so support is always tested per rung.
enum LightRung { onOff, brightness, colorTemp, color, effects }

/// HA `ColorMode` values that imply full colour selection.
const _colorModes = {'hs', 'xy', 'rgb', 'rgbw', 'rgbww'};

/// Capability descriptor for a lighting fixture, derived from its live state.
///
/// Lights advertise `supported_color_modes` / `effect_list`; a `switch.*`
/// fixture (a role-labelled wall switch driving lights) supports on/off only —
/// the bottom rung of the same ladder, not a parallel model.
///
/// Home Assistant has no attribute for "my colour temperature is discrete", so
/// stepped fixtures (notably template lights) supply their steps via app-side
/// configuration; see `colorTempSteps`.
class LightCapabilities {
  final Set<LightRung> rungs;

  /// Effect names available on this fixture. For a group this is HA's unioned
  /// `effect_list`.
  final List<String> effects;

  final int? minKelvin;
  final int? maxKelvin;

  /// Discrete colour temperatures in kelvin. Empty means the colour-temperature
  /// range is continuous between [minKelvin] and [maxKelvin].
  final List<int> colorTempSteps;

  const LightCapabilities({
    required this.rungs,
    this.effects = const [],
    this.minKelvin,
    this.maxKelvin,
    this.colorTempSteps = const [],
  });

  bool supports(LightRung rung) => rungs.contains(rung);

  /// True when the fixture offers nothing but on/off — a binary bulb or a
  /// switch-driven fixture.
  bool get isOnOffOnly =>
      rungs.length == 1 && rungs.contains(LightRung.onOff);

  /// True when colour temperature must be presented as discrete steps rather
  /// than a continuous sweep.
  bool get isSteppedColorTemp =>
      supports(LightRung.colorTemp) && colorTempSteps.isNotEmpty;

  /// Derives capabilities from live state.
  ///
  /// [colorTempSteps] comes from configuration for fixtures whose colour
  /// temperature is quantised; HA cannot advertise this.
  factory LightCapabilities.fromState(
    EntityState state, {
    List<int> colorTempSteps = const [],
  }) {
    // Non-light fixtures (role-labelled switches) are on/off only.
    if (state.domain != 'light') {
      return const LightCapabilities(rungs: {LightRung.onOff});
    }

    final modes = state.attrList<String>('supported_color_modes') ?? const [];
    final rungs = <LightRung>{LightRung.onOff};

    // Per HA: a light supporting only ColorMode.ONOFF is not dimmable. Any
    // other advertised mode implies brightness.
    if (modes.any((m) => m != 'onoff' && m != 'unknown')) {
      rungs.add(LightRung.brightness);
    }
    if (modes.contains('color_temp')) rungs.add(LightRung.colorTemp);
    if (modes.any(_colorModes.contains)) rungs.add(LightRung.color);

    final effects = state.attrList<String>('effect_list') ?? const [];
    if (effects.isNotEmpty) rungs.add(LightRung.effects);

    return LightCapabilities(
      rungs: rungs,
      effects: List.unmodifiable(effects),
      minKelvin: state.attrInt('min_color_temp_kelvin'),
      maxKelvin: state.attrInt('max_color_temp_kelvin'),
      colorTempSteps: List.unmodifiable(colorTempSteps),
    );
  }

  /// Descriptor for a fixture whose state has not loaded yet: assume on/off so
  /// the control renders something interactive rather than nothing.
  static const pending = LightCapabilities(rungs: {LightRung.onOff});
}
