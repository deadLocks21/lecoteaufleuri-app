import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Forme JSON d'une session : celle de la réponse de `POST /api/auth/verify-otp`,
/// reprise telle quelle pour la persistance locale.
abstract final class SessionCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static Session fromJson(Map<String, dynamic> json) {
    if (json case {
      'token': final String token,
      'expires_at': final String expiresAt,
      'user': {
        'id': final String id,
        'phone_number': final String phoneNumber,
        'first_name': final String firstName,
        'last_name': final String lastName,
      },
    } when token.isNotEmpty && id.isNotEmpty) {
      final parsedExpiry = DateTime.tryParse(expiresAt);
      if (parsedExpiry != null) {
        return Session(
          token: token,
          expiresAt: parsedExpiry,
          user: User(
            id: id,
            phoneNumber: phoneNumber,
            firstName: firstName,
            lastName: lastName,
          ),
        );
      }
    }
    throw const FormatException('Session JSON is malformed');
  }

  static Map<String, dynamic> toJson(Session session) => {
    'token': session.token,
    'expires_at': session.expiresAt.toUtc().toIso8601String(),
    'user': {
      'id': session.user.id,
      'phone_number': session.user.phoneNumber,
      'first_name': session.user.firstName,
      'last_name': session.user.lastName,
    },
  };
}
