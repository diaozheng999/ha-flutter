import 'package:flutter/material.dart';

/// Maximum track width for slider-based controls inside wide content panes —
/// sliders cap here instead of stretching across the window.
const double kControlMaxWidth = 480;

/// Width breakpoint (Material 3 "expanded") above which screens may use a
/// sidebar layout instead of the compact single-column layout.
const double kWideLayoutMinWidth = 840;

/// Fixed width of the room sidebar in the wide layout.
const double kRoomSidebarWidth = 300;

/// App-specific design tokens not covered by [ColorScheme], exposed as a
/// [ThemeExtension] so widgets read them via `Theme.of(context)`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  /// Monospace style for sensor readings, clock numerals, percentages.
  final TextStyle sensorStyle;

  /// Foreground/accent for an active ("on") device.
  final Color onAccent;

  /// Foreground for an inactive ("off") or unavailable device.
  final Color offMuted;

  /// Glass card fill and border.
  final Color glassFill;
  final Color glassBorder;

  /// Standard corner radius for cards.
  final double cardRadius;

  const AppTokens({
    required this.sensorStyle,
    required this.onAccent,
    required this.offMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.cardRadius,
  });

  @override
  AppTokens copyWith({
    TextStyle? sensorStyle,
    Color? onAccent,
    Color? offMuted,
    Color? glassFill,
    Color? glassBorder,
    double? cardRadius,
  }) {
    return AppTokens(
      sensorStyle: sensorStyle ?? this.sensorStyle,
      onAccent: onAccent ?? this.onAccent,
      offMuted: offMuted ?? this.offMuted,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      sensorStyle: TextStyle.lerp(sensorStyle, other.sensorStyle, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      offMuted: Color.lerp(offMuted, other.offMuted, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF4A90D9);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    const tokens = AppTokens(
      sensorStyle: TextStyle(
        fontFamily: 'monospace',
        fontFeatures: [FontFeature.tabularFigures()],
        letterSpacing: -0.5,
      ),
      onAccent: Color(0xFFFFD27D),
      offMuted: Color(0x8AFFFFFF),
      glassFill: Color(0x18FFFFFF),
      glassBorder: Color(0x30FFFFFF),
      cardRadius: 20,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // No fontFamily: resolve the platform system font (Roboto / Segoe UI).
      colorScheme: scheme.copyWith(
        surface: Colors.transparent,
      ),
      // The background engine paints behind everything; scaffolds stay clear.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xCC0A0A18),
        indicatorColor: scheme.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11),
        ),
      ),
      extensions: const [tokens],
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
