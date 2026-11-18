import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/auth/otp_verify.page.dart';
import 'package:lecoteaufleuri/ui/pages/auth/phone_entry.page.dart';
import 'package:lecoteaufleuri/ui/pages/home/home.page.dart';

/// Racine de l'app : n'ouvre l'accueil qu'à une session authentifiée, et
/// affiche sinon l'étape de connexion en cours.
///
/// Elle relit aussi les droits du compte à chaque retour au premier plan, et
/// referme tout écran ouvert par-dessus l'accueil quand la session se ferme ou
/// que le statut d'admin est retiré : rien de ce qu'il montrait ne reste
/// affiché ni en mémoire.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
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
    ref.listen(sessionControllerProvider, (previous, next) {
      final wasAdmin =
          previous is Authenticated && previous.session.user.isAdmin;
      final isAdmin = next is Authenticated && next.session.user.isAdmin;
      if ((previous is Authenticated && next is! Authenticated) ||
          (wasAdmin && !isAdmin)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

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
