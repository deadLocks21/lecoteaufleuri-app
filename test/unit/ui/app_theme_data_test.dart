import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/ui/theme/app_theme_data.dart';

/// Contraste WCAG 2 entre deux couleurs opaques.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('thème ${brightness.name}', () {
      final scheme = AppThemeData.buildColorScheme(brightness);
      final theme = brightness == Brightness.light
          ? AppThemeData.buildLightTheme()
          : AppThemeData.buildDarkTheme();

      test('le bouton principal prend le vert exact du logo', () {
        final style = theme.filledButtonTheme.style!;
        expect(style.backgroundColor!.resolve({}), AppThemeData.coteauGreen);
        expect(scheme.primaryContainer, AppThemeData.coteauGreen);
      });

      test('le bleu et le jaune ne colorent les fonds qu\'atténués', () {
        expect(scheme.secondaryContainer, isNot(AppThemeData.waterBlue));
        expect(scheme.tertiaryContainer, isNot(AppThemeData.sunYellow));
        expect(
          scheme.secondaryContainer,
          Color.alphaBlend(
            AppThemeData.waterBlue.withValues(alpha: AppThemeData.tintStrength),
            scheme.surface,
          ),
        );
      });

      test('chaque texte reste lisible sur son fond (WCAG AA)', () {
        final pairs = {
          'bouton': (scheme.primaryContainer, scheme.onPrimaryContainer),
          'lien': (scheme.surface, scheme.primary),
          'texte': (scheme.surface, scheme.onSurface),
          'texte secondaire': (scheme.surface, scheme.onSurfaceVariant),
          'fond bleu': (scheme.secondaryContainer, scheme.onSecondaryContainer),
          'fond jaune': (scheme.tertiaryContainer, scheme.onTertiaryContainer),
        };
        for (final MapEntry(key: name, value: (bg, fg)) in pairs.entries) {
          expect(contrast(bg, fg), greaterThanOrEqualTo(4.5), reason: name);
        }
      });
    });
  }

  test('le fond clair est le blanc du logo', () {
    expect(
      AppThemeData.buildColorScheme(Brightness.light).surface,
      Colors.white,
    );
  });
}
