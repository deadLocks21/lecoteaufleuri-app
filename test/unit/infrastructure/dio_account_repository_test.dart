import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/dio.account.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  const id = '0a5c0000-0000-4000-8000-0000000000ff';
  const userJson = {
    'id': id,
    'phone_number': '+33612345678',
    'first_name': 'Camille',
    'last_name': 'Martin',
    'is_admin': false,
  };
  final draft = AccountDraft.parse(
    rawPhone: '06 12 34 56 78',
    firstName: 'Camille',
    lastName: 'Martin',
  );

  Matcher failsWith(AccountErrorCode expected) =>
      throwsA(isA<AccountException>().having((e) => e.code, 'code', expected));

  ResponseBody noContent(RequestOptions _) => ResponseBody.fromString('', 204);

  test('liste les comptes', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'users': [userJson],
      }),
    );

    final users = await DioAccountRepository(dioWith(adapter)).list();

    expect(users.single.lastName, 'Martin');
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/admin/users');
  });

  test('crée et corrige un compte avec le numéro en E.164', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(userJson));
    final repository = DioAccountRepository(dioWith(adapter));

    await repository.create(draft);
    await repository.update(id, draft);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'POST /api/admin/users',
      'PUT /api/admin/users/$id',
    ]);
    expect(adapter.requests.first.data, {
      'phone_number': '+33612345678',
      'first_name': 'Camille',
      'last_name': 'Martin',
    });
  });

  test('nomme et retire un admin', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(userJson));
    final repository = DioAccountRepository(dioWith(adapter));

    await repository.setAdmin(id, admin: true);
    await repository.setAdmin(id, admin: false);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'PUT /api/admin/users/$id/admin',
      'DELETE /api/admin/users/$id/admin',
    ]);
  });

  test('supprime et coupe les sessions (204, sans corps)', () async {
    final adapter = FakeHttpAdapter(noContent);
    final repository = DioAccountRepository(dioWith(adapter));

    await repository.delete(id);
    await repository.revokeSessions(id);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'DELETE /api/admin/users/$id',
      'POST /api/admin/users/$id/revoke-sessions',
    ]);
  });

  test('traduit chaque code d\'erreur de l\'API', () async {
    const expected = {
      'forbidden': AccountErrorCode.forbidden,
      'user_not_found': AccountErrorCode.notFound,
      'phone_number_already_registered': AccountErrorCode.phoneTaken,
      'invalid_phone_format': AccountErrorCode.invalidPhone,
      'invalid_user_name': AccountErrorCode.invalidName,
      'last_admin': AccountErrorCode.lastAdmin,
      'invalid_token': AccountErrorCode.sessionExpired,
      'something_new': AccountErrorCode.unknown,
    };
    for (final MapEntry(key: apiCode, value: code) in expected.entries) {
      final repository = DioAccountRepository(
        dioWith(
          FakeHttpAdapter(
            (_) => FakeHttpAdapter.json({
              'error': 'Message',
              'code': apiCode,
            }, status: 409),
          ),
        ),
      );

      await expectLater(repository.list(), failsWith(code), reason: apiCode);
    }
  });

  test('une réponse qui n\'est pas celle de l\'API est reconnue', () {
    expect(
      DioAccountRepository(
        dioWith(FakeHttpAdapter((_) => FakeHttpAdapter.html())),
      ).list(),
      failsWith(AccountErrorCode.badServerUrl),
    );
    expect(
      DioAccountRepository(
        dioWith(FakeHttpAdapter((_) => FakeHttpAdapter.json({'oops': 1}))),
      ).create(draft),
      failsWith(AccountErrorCode.badServerUrl),
    );
  });
}
