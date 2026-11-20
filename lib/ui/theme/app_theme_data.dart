import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/ui/theme/page_transitions.dart';

/// Assemble les thèmes Material 3 clair/sombre de l'app à partir des couleurs
/// du logo (`design/logo.jpg` du dépôt dev) : palette « logo à l'identique ».
///
/// - Les accents gardent la couleur exacte du logo : le bouton principal est
///   vert coteau avec un texte anthracite, comme le nom sous le logo.
/// - Les fonds colorés (bandeaux, pastilles) en sont une version atténuée, et
///   le texte posé dessus prend la teinte foncée de la même couleur.
/// - Les textes colorés (liens, champ actif) passent par le vert profond de la
///   gamme Material, le vert du logo étant illisible en petit sur du blanc.
/// - Les neutres sont de vrais gris : fond blanc et texte anthracite en clair.
abstract final class AppThemeData {
  /// La colline : couleur dominante.
  static const coteauGreen = Color(0xFF8CD35F);

  /// Le plan d'eau.
  static const waterBlue = Color(0xFF29D3FF);

  /// Le soleil.
  static const sunYellow = Color(0xFFFDD014);

  /// Le nom du domaine.
  static const charcoal = Color(0xFF515150);

  /// Part de la couleur du logo dans un fond coloré : au-delà, le bleu et le
  /// jaune deviennent criards en aplat.
  static const tintStrength = 0.18;

  static const _inkLight = Color(0xFF242423);
  static const _inkDark = Color(0xFF1C1C1B);

  static ThemeData buildLightTheme() => _build(Brightness.light);
  static ThemeData buildDarkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = buildColorScheme(brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Le cadre passe à `PageTransitions.wide` sur grand écran.
      pageTransitionsTheme: PageTransitions.compact,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  static ColorScheme buildColorScheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    // Variante « fidelity » : chaque gamme garde la saturation de la couleur
    // du logo, au lieu de la ternir comme le réglage par défaut.
    ColorScheme fromLogo(Color color) => ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final green = fromLogo(coteauGreen);
    final water = fromLogo(waterBlue);
    final sun = fromLogo(sunYellow);
    final neutral = ColorScheme.fromSeed(
      seedColor: charcoal,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );

    final surface = isLight ? Colors.white : neutral.surface;
    final ink = isLight ? _inkLight : _inkDark;
    // Couleur opaque, et non transparence : le rendu et les contrastes ne
    // dépendent pas de ce qui se trouve dessous.
    Color tinted(Color color) =>
        Color.alphaBlend(color.withValues(alpha: tintStrength), surface);

    return green.copyWith(
      primaryContainer: coteauGreen,
      onPrimaryContainer: ink,
      secondary: water.primary,
      onSecondary: water.onPrimary,
      secondaryContainer: tinted(waterBlue),
      onSecondaryContainer: water.primary,
      tertiary: sun.primary,
      onTertiary: sun.onPrimary,
      tertiaryContainer: tinted(sunYellow),
      onTertiaryContainer: sun.primary,
      surface: surface,
      onSurface: isLight ? _inkLight : neutral.onSurface,
      onSurfaceVariant: isLight ? charcoal : neutral.onSurfaceVariant,
      surfaceDim: neutral.surfaceDim,
      surfaceBright: neutral.surfaceBright,
      surfaceContainerLowest: neutral.surfaceContainerLowest,
      surfaceContainerLow: neutral.surfaceContainerLow,
      surfaceContainer: neutral.surfaceContainer,
      surfaceContainerHigh: neutral.surfaceContainerHigh,
      surfaceContainerHighest: neutral.surfaceContainerHighest,
      outline: neutral.outline,
      outlineVariant: neutral.outlineVariant,
      inverseSurface: neutral.inverseSurface,
      onInverseSurface: neutral.onInverseSurface,
    );
  }
}
