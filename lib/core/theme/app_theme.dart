import 'package:flutter/material.dart';

/// A warm, low-saturation palette instead of Flutter's default Material
/// purple — deliberately calmer, matching a meditation/breathing app rather
/// than a generic productivity app. Individual screens (especially the
/// shloka detail view) may layer their own accents on top of this base.
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFFB8895A); // warm terracotta

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
