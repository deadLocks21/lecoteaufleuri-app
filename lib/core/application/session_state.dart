import 'package:lecoteaufleuri/core/application/dtos/session.dto.dart';

/// Machine d'états de la session ; `AuthGate` en déduit l'écran affiché.
///
/// Transitions :
/// - SessionRestoring → Authenticated  (session enregistrée encore valable)
/// - SessionRestoring → Anonymous      (aucune session, ou expirée)
/// - Anonymous        → OtpRequested   (requestOtp ; échoue si compte inconnu)
/// - OtpRequested     → OtpRequested   (resendOtp)
/// - OtpRequested     → Authenticated  (verifyOtp)
/// - OtpRequested     → Anonymous      (backToPhoneEntry)
/// - Authenticated    → OtpRequested   (expire : 401 `invalid_token`, SMS renvoyé)
/// - Authenticated    → Anonymous      (expire sans SMS possible, logout)
sealed class SessionState {
  const SessionState();
}

/// Démarrage : lecture de la session enregistrée.
class SessionRestoring extends SessionState {
  const SessionRestoring();
}

/// Personne n'est connecté : saisie du numéro.
class Anonymous extends SessionState {
  const Anonymous();
}

/// Pourquoi un code a été demandé : l'écran OTP adapte son message.
enum OtpReason { login, sessionExpired }

/// Un code est parti par SMS vers [phoneNumber] (E.164) ; il attend d'être saisi.
class OtpRequested extends SessionState {
  final String phoneNumber;
  final DateTime expiresAt;
  final OtpReason reason;

  const OtpRequested({
    required this.phoneNumber,
    required this.expiresAt,
    this.reason = OtpReason.login,
  });
}

/// Session ouverte.
class Authenticated extends SessionState {
  final SessionDto session;

  const Authenticated(this.session);
}
