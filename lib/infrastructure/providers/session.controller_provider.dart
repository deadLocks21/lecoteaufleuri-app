import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/services/auth_application.service.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session.controller_provider.g.dart';

/// Pilote la [SessionState] : seul point de contact entre l'UI et les cas
/// d'usage de connexion.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AuthErrorCode] que
/// l'écran traduit en message.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  AuthApplicationService get _service => ref.read(authServiceProvider);

  @override
  SessionState build() {
    // Hors du build : il ne doit rien lire ni écrire d'autre que son état.
    Future.microtask(_restore);
    return const SessionRestoring();
  }

  Future<void> _restore() async {
    final session = await _run(_service.restoreSession.execute);
    if (!ref.mounted) return;
    state = switch (session) {
      (final restored?, null) => Authenticated(restored),
      // Aucune session, ou stockage illisible : retour à la connexion.
      _ => const Anonymous(),
    };
    // L'accueil s'ouvre sur ce qu'on sait ; les droits du moment suivent.
    if (state is Authenticated) await refresh();
  }

  /// Relit le compte auprès du serveur : ses droits ont pu changer depuis la
  /// connexion (admin nommé ou retiré…). Sans réseau, on garde ce qu'on sait ;
  /// un jeton refusé passe par [expire] (cf. `AuthInterceptor`).
  Future<void> refresh() async {
    if (state is! Authenticated) return;
    final (session, _) = await _run(_service.refreshSession.execute);
    if (session != null && ref.mounted && state is Authenticated) {
      state = Authenticated(session);
    }
  }

  Future<AuthErrorCode?> requestOtp(
    String rawPhone, {
    OtpReason reason = OtpReason.login,
  }) async {
    final (otp, error) = await _run(
      () => _service.requestOtp.execute(rawPhone),
    );
    if (otp != null && ref.mounted) {
      state = OtpRequested(
        phoneNumber: otp.phoneNumber,
        expiresAt: otp.expiresAt,
        reason: reason,
      );
    }
    return error;
  }

  /// Renvoie un code au numéro en attente (le délai entre deux envois est
  /// imposé par l'écran).
  Future<AuthErrorCode?> resendOtp() async {
    final current = state;
    if (current is! OtpRequested) return AuthErrorCode.otpExpired;
    return requestOtp(current.phoneNumber, reason: current.reason);
  }

  Future<AuthErrorCode?> verifyOtp(String rawCode) async {
    final current = state;
    if (current is! OtpRequested) return AuthErrorCode.otpExpired;
    final (session, error) = await _run(
      () => _service.verifyOtp.execute(
        phoneNumber: current.phoneNumber,
        rawCode: rawCode,
      ),
    );
    if (session != null && ref.mounted) state = Authenticated(session);
    return error;
  }

  /// Corriger le numéro saisi.
  void backToPhoneEntry() {
    if (state is OtpRequested) state = const Anonymous();
  }

  Future<void> logout() async {
    state = const Anonymous();
    await _run(_service.logout.execute);
  }

  /// Réaction au `401 invalid_token` (jeton expiré ou refusé) : la session est
  /// morte, on renvoie un SMS au numéro du compte pour que l'utilisateur n'ait
  /// plus qu'à saisir le code.
  ///
  /// Quitter tout de suite [Authenticated] sert de verrou : les requêtes
  /// concurrentes qui prennent aussi un 401 retombent ici sans renvoyer de SMS
  /// (le quota serveur est de 3 envois par quart d'heure). Si l'envoi échoue,
  /// l'utilisateur reste sur la saisie du numéro.
  Future<void> expire() async {
    final current = state;
    if (current is! Authenticated) return;
    state = const Anonymous();
    await _run(_service.logout.execute);
    await requestOtp(
      current.session.user.phoneNumber,
      reason: OtpReason.sessionExpired,
    );
  }

  /// Exécute un cas d'usage et rend son résultat ou son code d'échec. Une
  /// erreur inattendue (stockage indisponible…) devient `unknown` plutôt que
  /// de laisser un écran bloqué sur son indicateur de chargement.
  Future<(T?, AuthErrorCode?)> _run<T>(Future<T> Function() action) async {
    try {
      return (await action(), null);
    } on AuthException catch (e) {
      return (null, e.code);
    } catch (e, stack) {
      debugPrint('session: échec inattendu : $e\n$stack');
      return (null, AuthErrorCode.unknown);
    }
  }
}
