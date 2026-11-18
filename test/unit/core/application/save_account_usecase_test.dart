import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/accounts.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';

void main() {
  late InMemoryAccountRepository accounts;
  late SaveAccountUseCase save;

  Matcher failsWith(AccountErrorCode expected) =>
      throwsA(isA<AccountException>().having((e) => e.code, 'code', expected));

  setUp(() {
    accounts = InMemoryAccountRepository();
    save = SaveAccountUseCase(accounts);
  });

  test('crée un compte à partir d\'une saisie libre', () async {
    final created = await save.execute(
      rawPhone: '07 11 22 33 44',
      firstName: '  Lou ',
      lastName: 'Petit',
    );

    expect(created.phoneNumber, '+33711223344');
    expect(created.firstName, 'Lou');
    expect(created.isAdmin, isFalse);
  });

  test('corrige le compte désigné', () async {
    final existing = (await accounts.list()).first;

    final updated = await save.execute(
      id: existing.id,
      rawPhone: existing.phoneNumber,
      firstName: existing.firstName,
      lastName: 'Nouveau',
    );

    expect(updated.id, existing.id);
    expect(updated.lastName, 'Nouveau');
  });

  test('refuse un numéro invalide ou un nom vide avant tout appel', () {
    expect(
      save.execute(rawPhone: '01 23', firstName: 'Lou', lastName: 'Petit'),
      failsWith(AccountErrorCode.invalidPhone),
    );
    expect(
      save.execute(
        rawPhone: '07 11 22 33 44',
        firstName: ' ',
        lastName: 'Petit',
      ),
      failsWith(AccountErrorCode.invalidName),
    );
  });
}
