import 'package:flutter/material.dart';

/// Les transitions entre écrans, en un seul endroit.
///
/// - Sur téléphone, un écran ouvert glisse depuis la droite et repart par la
///   droite (on revient d'un geste, sur iOS) : partout pareil, quelle que
///   soit la plateforme.
/// - Sur grand écran, un fondu zoomé, partout pareil lui aussi : passer d'un
///   module à l'autre par la barre latérale ne fait pas glisser le contenu
///   (Material glisserait sur macOS et iOS).
abstract final class PageTransitions {
  static final compact = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: CupertinoPageTransitionsBuilder(),
    },
  );

  static final wide = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const ZoomPageTransitionsBuilder(),
    },
  );
}
