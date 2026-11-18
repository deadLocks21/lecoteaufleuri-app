import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/ui/theme/app_theme_data.dart';
import 'package:lecoteaufleuri/ui/widgets/auth_gate.widget.dart';

void main() {
  runApp(const ProviderScope(child: LeCoteauFleuriApp()));
}

class LeCoteauFleuriApp extends StatelessWidget {
  const LeCoteauFleuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Coteau Fleuri',
      theme: AppThemeData.buildLightTheme(),
      darkTheme: AppThemeData.buildDarkTheme(),
      debugShowCheckedModeBanner: false,
      // L'app est en français, widgets Material compris (calendriers, boutons
      // des dialogues, infobulles).
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}
