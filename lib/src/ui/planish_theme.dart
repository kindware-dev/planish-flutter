import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Planish's colours: the same tokens as Planish Cloud and its web widget,
/// in light and dark.
@immutable
class PlanishColors {
  const PlanishColors._({
    required this.brightness,
    required this.background,
    required this.panel,
    required this.panel2,
    required this.line,
    required this.line2,
    required this.text,
    required this.muted,
    required this.faint,
    required this.brand,
    required this.brandStrong,
    required this.brandTint,
    required this.onBrand,
    required this.cyan,
    required this.coral,
    required this.coralTint,
    required this.warning,
    required this.ok,
    required this.violet,
  });

  static const PlanishColors light = PlanishColors._(
    brightness: Brightness.light,
    background: Color(0xFFF4F6FB),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFEFF2F8),
    line: Color(0xFFE2E7F0),
    line2: Color(0xFFEDF0F6),
    text: Color(0xFF101A36),
    muted: Color(0xFF4D5777),
    faint: Color(0xFF5F6887),
    brand: Color(0xFF245BEE),
    brandStrong: Color(0xFF1A47C9),
    brandTint: Color(0xFFEAF0FF),
    onBrand: Color(0xFFFFFFFF),
    cyan: Color(0xFF056B80),
    coral: Color(0xFFC42F1E),
    coralTint: Color(0xFFFFF0ED),
    warning: Color(0xFF9C5A00),
    ok: Color(0xFF127A4C),
    violet: Color(0xFF6546E0),
  );

  static const PlanishColors dark = PlanishColors._(
    brightness: Brightness.dark,
    background: Color(0xFF090E1D),
    panel: Color(0xFF10172F),
    panel2: Color(0xFF161F3E),
    line: Color(0xFF212B4B),
    line2: Color(0xFF19223F),
    text: Color(0xFFE8ECF8),
    muted: Color(0xFFA6B0CF),
    faint: Color(0xFF8590B8),
    brand: Color(0xFF7298FF),
    brandStrong: Color(0xFF93B1FF),
    brandTint: Color(0xFF17255A),
    onBrand: Color(0xFF081030),
    cyan: Color(0xFF41E3FF),
    coral: Color(0xFFFF7A68),
    coralTint: Color(0xFF361923),
    warning: Color(0xFFFFBF5E),
    ok: Color(0xFF5FDFA1),
    violet: Color(0xFFB5A3FF),
  );

  static PlanishColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  final Brightness brightness;

  /// Page background, and the fill of text fields.
  final Color background;

  /// Cards, sheets, dialogs.
  final Color panel;

  /// Raised parts of a panel: segmented controls, attachment cards.
  final Color panel2;

  /// Borders and dividers.
  final Color line;

  /// Faint dividers inside lists.
  final Color line2;

  final Color text;
  final Color muted;
  final Color faint;

  /// Fills: buttons, selected tabs.
  final Color brand;

  /// Pressed or hovered fills.
  final Color brandStrong;

  /// Tinted background of a selected item.
  final Color brandTint;

  /// Text and icons on [brand].
  final Color onBrand;

  final Color cyan;
  final Color coral;
  final Color coralTint;
  final Color warning;
  final Color ok;
  final Color violet;
}

/// The theme of the screens Planish shows end users, built on [PlanishColors]
/// in the app's brightness. It keeps the app's fonts.
///
/// With [brand], buttons take that colour as given, while text, links and
/// outlines take a shade of it that reads at 4.5:1 on the panel, as the web
/// widget's `data-color` does.
ThemeData planishTheme(BuildContext context, {Color? brand}) {
  final app = Theme.of(context);
  final c = PlanishColors.of(app.brightness);
  final fill = brand == null ? c.brand : _fill(brand, c);
  final ink = brand == null ? c.brand : _readable(brand, c);
  final onFill = brand == null ? c.onBrand : _onFill(fill, c);
  final scheme = ColorScheme(
    brightness: c.brightness,
    primary: ink,
    onPrimary: _onFill(ink, c),
    primaryContainer: c.brandTint,
    onPrimaryContainer: ink,
    secondary: c.cyan,
    onSecondary: c.panel,
    // Selected segments and chips: the brand tint, as on the web.
    secondaryContainer: c.brandTint,
    onSecondaryContainer: ink,
    tertiary: c.violet,
    onTertiary: c.panel,
    error: c.coral,
    onError: c.panel,
    errorContainer: c.coralTint,
    onErrorContainer: c.coral,
    surface: c.panel,
    onSurface: c.text,
    surfaceContainerLowest: c.panel,
    surfaceContainerLow: c.background,
    surfaceContainer: c.panel2,
    surfaceContainerHigh: c.panel2,
    surfaceContainerHighest: c.line,
    onSurfaceVariant: c.muted,
    outline: c.faint,
    outlineVariant: c.line,
    inverseSurface: c.text,
    onInverseSurface: c.panel,
    inversePrimary: c.brandTint,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c.line),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.panel,
    canvasColor: c.panel,
    dividerColor: c.line,
    textTheme: app.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.panel,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    // Set explicitly: Theme otherwise keeps the cursor colour of the app's theme.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ink,
      selectionColor: ink.withValues(alpha: 0.3),
      selectionHandleColor: ink,
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.background,
      hintStyle: TextStyle(color: c.faint),
      border: field,
      enabledBorder: field,
      focusedBorder: field.copyWith(
        borderSide: BorderSide(color: ink, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: onFill,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: fill,
      foregroundColor: onFill,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: TextStyle(color: c.panel),
    ),
  );
}

/// [brand] as given, unless it would vanish into the panel.
Color _fill(Color brand, PlanishColors c) =>
    _contrast(brand, c.panel) >= 1.3 ? brand : _readable(brand, c);

/// [brand] moved towards black (light) or white (dark) until it reads at
/// 4.5:1 on the panel.
Color _readable(Color brand, PlanishColors c) {
  final light = c.brightness == Brightness.light;
  final start = light ? brand : Color.lerp(brand, Colors.white, 0.3)!;
  final target = light ? Colors.black : Colors.white;
  var out = start;
  for (var t = 0.1; _contrast(out, c.panel) < 4.5 && t <= 1; t += 0.1) {
    out = Color.lerp(start, target, t)!;
  }
  return out;
}

/// White or the dark ink on [fill], whichever reads better.
Color _onFill(Color fill, PlanishColors c) {
  final ink = c.brightness == Brightness.light
      ? PlanishColors.light.text
      : PlanishColors.dark.onBrand;
  return _contrast(Colors.white, fill) >= _contrast(ink, fill)
      ? Colors.white
      : ink;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
