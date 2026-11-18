import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/infrastructure/auth/user.codec.dart';

/// Forme JSON d'une session : celle de la réponse de `POST /api/auth/verify-otp`,
/// reprise telle quelle pour la persistance locale.
abstract final class SessionCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static Session fromJson(Map<String, dynamic> json) {
    if (json case {
      'token': final String token,
      'expires_at': final String expiresAt,
      'user': final Object user,
    } when token.isNotEmpty) {
      final parsedExpiry = DateTime.tryParse(expiresAt);
      if (parsedExpiry != null) {
        return Session(
          token: token,
          expiresAt: parsedExpiry,
          user: UserCodec.fromJson(user),
        );
      }
    }
    throw const FormatException('Session JSON is malformed');
  }

  static Map<String, dynamic> toJson(Session session) => {
    'token': session.token,
    'expires_at': session.expiresAt.toUtc().toIso8601String(),
    'user': UserCodec.toJson(session.user),
  };
}
