import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';

/// Value object : mobile français normalisé au format E.164 (`+33612345678`),
/// le seul que l'API accepte.
class PhoneNumber {
  /// Forme E.164, ex. `+33612345678`.
  final String e164;

  const PhoneNumber._(this.e164);

  static final _e164 = RegExp(r'^\+33[67]\d{8}$');

  /// Normalise une saisie libre (`06 12 34 56 78`, `+33 6 12…`, `0033 6…`)
  /// puis la valide. Lève `AuthException(invalidPhone)` sinon.
  factory PhoneNumber.parse(String raw) {
    var digits = raw.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (digits.startsWith('00')) {
      digits = '+${digits.substring(2)}';
    } else if (digits.startsWith('0') && digits.length == 10) {
      digits = '+33${digits.substring(1)}';
    } else if (digits.startsWith('33') && digits.length == 11) {
      digits = '+$digits';
    }
    if (!_e164.hasMatch(digits)) {
      throw const AuthException(AuthErrorCode.invalidPhone);
    }
    return PhoneNumber._(digits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  @override
  String toString() => e164;
}
