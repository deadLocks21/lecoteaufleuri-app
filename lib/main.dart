import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/providers/app_router.provider.dart';
import 'package:lecoteaufleuri/ui/theme/app_theme_data.dart';

void main() {
  runApp(const ProviderScope(child: LeCoteauFleuriApp()));
}

/// L'app : son thème, sa langue, et son routeur, qui décide de l'écran
/// d'après la session (cf. `appRouter`).
///
/// Elle relit aussi les droits du compte à chaque retour au premier plan.
class LeCoteauFleuriApp extends ConsumerStatefulWidget {
  const LeCoteauFleuriApp({super.key});

  @override
  ConsumerState<LeCoteauFleuriApp> createState() => _LeCoteauFleuriAppState();
}

class _LeCoteauFleuriAppState extends ConsumerState<LeCoteauFleuriApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(sessionControllerProvider.notifier).refresh()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Le Coteau Fleuri',
      theme: AppThemeData.buildLightTheme(),
      darkTheme: AppThemeData.buildDarkTheme(),
      debugShowCheckedModeBanner: false,
      // L'app est en français, widgets Material compris (calendriers, boutons
      // des dialogues, infobulles).
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
