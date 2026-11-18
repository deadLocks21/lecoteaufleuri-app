import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';

/// Ce qu'un admin saisit pour créer ou corriger un compte, validé avant
/// d'être envoyé : numéro normalisé en E.164, prénom et nom non vides.
class AccountDraft {
  final PhoneNumber phone;
  final String firstName;
  final String lastName;

  const AccountDraft._(this.phone, this.firstName, this.lastName);

  /// Lève `AccountException(invalidPhone | invalidName)`.
  factory AccountDraft.parse({
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) {
    final PhoneNumber phone;
    try {
      phone = PhoneNumber.parse(rawPhone);
    } on AuthException {
      throw const AccountException(AccountErrorCode.invalidPhone);
    }
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty || last.isEmpty) {
      throw const AccountException(AccountErrorCode.invalidName);
    }
    return AccountDraft._(phone, first, last);
  }
}
