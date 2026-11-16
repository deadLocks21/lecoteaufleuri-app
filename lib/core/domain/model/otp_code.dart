import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';

/// Value object : le code à 6 chiffres reçu par SMS.
class OtpCode {
  final String value;

  const OtpCode._(this.value);

  static final _sixDigits = RegExp(r'^\d{6}$');

  /// Lève `AuthException(invalidOtp)` si [raw] n'a pas exactement 6 chiffres :
  /// inutile de déranger le serveur (et de consommer un essai) pour ça.
  factory OtpCode.parse(String raw) {
    final trimmed = raw.trim();
    if (!_sixDigits.hasMatch(trimmed)) {
      throw const AuthException(AuthErrorCode.invalidOtp);
    }
    return OtpCode._(trimmed);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OtpCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
