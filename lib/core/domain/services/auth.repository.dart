import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Port d'authentification par numéro de mobile + code reçu par SMS (OTP).
///
/// Pas d'inscription : les comptes sont créés côté serveur. Tout échec est
/// signalé par une `AuthException` (ex. `accountNotFound` pour un numéro
/// inconnu).
abstract interface class AuthRepository {
  /// Fait envoyer un code au numéro d'un compte existant ; renvoie l'échéance
  /// du code.
  Future<DateTime> requestOtp(PhoneNumber phone);

  /// Échange le code reçu contre une session.
  Future<Session> verifyOtp(PhoneNumber phone, OtpCode code);

  /// Le compte de la session en cours, relu sur le serveur (droits compris).
  Future<User> currentUser();
}
