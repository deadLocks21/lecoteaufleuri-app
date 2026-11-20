import 'package:flutter/material.dart';

/// Les transitions entre écrans, en un seul endroit.
///
/// - Sur téléphone, un écran ouvert glisse depuis la droite et repart par la
///   droite (on revient d'un geste, sur iOS) : partout pareil, quelle que
///   soit la plateforme.
/// - Sur grand écran, passer d'un module à l'autre ne s'anime pas (le menu
///   reste en place, seul le contenu change), et un écran ouvert dans le
///   contenu (éditeur d'un jour…) apparaît en fondu.
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
        platform: FadePageTransitionsBuilder(),
    },
  );
}

/// Un fondu bref : l'écran qui s'ouvre apparaît sur celui d'avant.
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}
