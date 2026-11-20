import 'package:flutter/material.dart';

/// Les transitions entre écrans, en un seul endroit.
///
/// - Sur téléphone, un écran ouvert glisse depuis la droite et repart par la
///   droite (on revient d'un geste, sur iOS) : partout pareil, quelle que
///   soit la plateforme.
/// - Sur grand écran, les transitions de Material, propres à chaque
///   plateforme, entre modules comme pour un écran ouvert dans le contenu.
abstract final class PageTransitions {
  static final compact = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: CupertinoPageTransitionsBuilder(),
    },
  );

  static const wide = PageTransitionsTheme();
}
