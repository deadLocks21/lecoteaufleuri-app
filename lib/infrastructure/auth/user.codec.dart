import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Forme JSON d'un compte, celle de l'objet `user` de l'API, reprise telle
/// quelle dans la session enregistrée.
abstract final class UserCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  ///
  /// `is_admin` manque dans les sessions enregistrées avant son ajout : il
  /// vaut alors `false`, et la prochaine relecture de `/api/me` le corrige.
  static User fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'phone_number': final String phoneNumber,
      'first_name': final String firstName,
      'last_name': final String lastName,
    } when id.isNotEmpty) {
      final isAdmin = switch ((json as Map)['is_admin']) {
        null => false,
        final bool value => value,
        _ => throw const FormatException('User JSON is malformed'),
      };
      return User(
        id: id,
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        isAdmin: isAdmin,
      );
    }
    throw const FormatException('User JSON is malformed');
  }

  static Map<String, dynamic> toJson(User user) => {
    'id': user.id,
    'phone_number': user.phoneNumber,
    'first_name': user.firstName,
    'last_name': user.lastName,
    'is_admin': user.isAdmin,
  };
}
