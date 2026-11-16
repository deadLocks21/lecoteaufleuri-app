import 'package:flutter/material.dart';

/// Assemble les thèmes Material 3 clair/sombre de l'app.
abstract final class AppThemeData {
  /// Vert du coteau, relevé sur le logo (`design/logo.jpg` du dépôt dev).
  static const brandGreen = Color(0xFF8DD35F);

  static ThemeData buildLightTheme() => _build(Brightness.light);
  static ThemeData buildDarkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: brightness,
    ),
  );
}
