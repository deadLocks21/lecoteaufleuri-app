import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/auth/otp_verify.page.dart';
import 'package:lecoteaufleuri/ui/pages/auth/phone_entry.page.dart';
import 'package:lecoteaufleuri/ui/pages/home/home.page.dart';

/// Racine de l'app : n'ouvre l'accueil qu'à une session authentifiée, et
/// affiche sinon l'étape de connexion en cours.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(sessionControllerProvider)) {
      SessionRestoring() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      Anonymous() => const PhoneEntryPage(),
      OtpRequested() => const OtpVerifyPage(),
      Authenticated() => const HomePage(),
    };
  }
}
