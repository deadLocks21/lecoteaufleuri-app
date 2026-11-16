import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Session ouverte par un OTP valide : le JWT, sa date d'expiration et le
/// compte connecté.
class Session {
  /// Marge avant l'expiration réelle : un jeton sur le point d'expirer serait
  /// refusé au milieu d'une requête.
  static const expiryMargin = Duration(minutes: 1);

  final String token;
  final DateTime expiresAt;
  final User user;

  const Session({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  bool isExpiredAt(DateTime now) =>
      !now.isBefore(expiresAt.subtract(expiryMargin));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          other.token == token &&
          other.expiresAt == expiresAt &&
          other.user == user;

  @override
  int get hashCode => Object.hash(token, expiresAt, user);
}
