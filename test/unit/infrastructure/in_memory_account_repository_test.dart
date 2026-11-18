import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';

/// Le double en mémoire suit les mêmes règles que l'API.
void main() {
  late InMemoryAccountRepository accounts;
  final demoId = InMemoryAuthRepository.demoUser.id;

  Matcher failsWith(AccountErrorCode expected) =>
      throwsA(isA<AccountException>().having((e) => e.code, 'code', expected));

  AccountDraft draft(String phone) =>
      AccountDraft.parse(rawPhone: phone, firstName: 'Lou', lastName: 'Petit');

  setUp(() => accounts = InMemoryAccountRepository());

  test('liste par nom puis prénom', () async {
    expect((await accounts.list()).map((u) => u.lastName), [
      'Bernard',
      'Durand',
      'Démo',
    ]);
  });

  test('un numéro ne sert qu\'à un compte', () async {
    await accounts.create(draft('07 11 22 33 44'));

    expect(
      accounts.create(draft('07 11 22 33 44')),
      failsWith(AccountErrorCode.phoneTaken),
    );
  });

  test('le dernier admin ne perd ni son statut ni son compte', () {
    expect(
      accounts.setAdmin(demoId, admin: false),
      failsWith(AccountErrorCode.lastAdmin),
    );
    expect(accounts.delete(demoId), failsWith(AccountErrorCode.lastAdmin));
  });

  test('un compte inconnu est introuvable', () {
    expect(
      accounts.revokeSessions('nobody'),
      failsWith(AccountErrorCode.notFound),
    );
  });
}
