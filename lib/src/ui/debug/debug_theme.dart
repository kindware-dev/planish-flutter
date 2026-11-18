import 'package:flutter/material.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/ui/planish_theme.dart';

/// Colors the debug widgets read. Registered as a theme extension by
/// [debugToolsTheme]; derived from the app's `ColorScheme` when the tools
/// use the app theme instead.
class DebugPalette extends ThemeExtension<DebugPalette> {
  const DebugPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.info,
    required this.warning,
    required this.error,
    required this.dim,
  });

  /// Planish's palette for [colors].
  factory DebugPalette.planish(PlanishColors colors) => DebugPalette(
    background: colors.background,
    surface: colors.panel,
    surfaceHigh: colors.panel2,
    border: colors.line,
    text: colors.text,
    muted: colors.muted,
    accent: colors.brand,
    info: colors.cyan,
    warning: colors.warning,
    error: colors.coral,
    dim: colors.faint,
  );

  /// A palette that follows [scheme], for `useAppTheme`.
  factory DebugPalette.fromScheme(ColorScheme scheme) => DebugPalette(
    background: scheme.surface,
    surface: scheme.surfaceContainerLow,
    surfaceHigh: scheme.surfaceContainerHigh,
    border: scheme.outlineVariant,
    text: scheme.onSurface,
    muted: scheme.onSurfaceVariant,
    accent: scheme.primary,
    info: scheme.tertiary,
    warning: PlanishColors.of(scheme.brightness).warning,
    error: scheme.error,
    dim: scheme.onSurfaceVariant.withValues(alpha: 0.7),
  );

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color info;
  final Color warning;
  final Color error;
  final Color dim;

  /// Palette of the nearest theme, or one derived from its color scheme.
  static DebugPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<DebugPalette>() ??
        DebugPalette.fromScheme(theme.colorScheme);
  }

  @override
  DebugPalette copyWith() => this;

  @override
  DebugPalette lerp(DebugPalette? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Material theme used inside every debug tool page and panel: Planish's
/// colours in the app's brightness.
ThemeData debugToolsTheme(BuildContext context) {
  final theme = planishTheme(context);
  final c = PlanishColors.of(theme.brightness);
  return theme.copyWith(
    extensions: [DebugPalette.planish(c)],
    scaffoldBackgroundColor: c.background,
    appBarTheme: theme.appBarTheme.copyWith(backgroundColor: c.background),
    listTileTheme: ListTileThemeData(iconColor: c.muted, textColor: c.text),
    chipTheme: ChipThemeData(
      backgroundColor: c.panel2,
      selectedColor: c.brandTint,
      side: BorderSide(color: c.line),
      labelStyle: TextStyle(color: c.text, fontSize: 12),
      checkmarkColor: c.brand,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      fillColor: c.panel2,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.text),
    ),
  );
}

/// Applies [debugToolsTheme] to [child].
class DebugToolsTheme extends StatelessWidget {
  const DebugToolsTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tools = Planish.config.debugTools;
    final data = tools.useAppTheme
        ? Theme.of(context)
        : tools.theme?.call(context) ?? debugToolsTheme(context);
    return Theme(data: data, child: child);
  }
}
