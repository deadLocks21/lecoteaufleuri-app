import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/stays/dio.stay.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  const stayJson = {
    'id': '5d1e0000-0000-4000-8000-000000000001',
    'name': 'Été 2027',
    'kind': 'acm',
    'starts_on': '2027-07-10',
    'ends_on': '2027-07-24',
  };
  final draft = StayDraft.parse(
    name: 'Été 2027',
    kind: StayKind.acm,
    startsOn: DateTime(2027, 7, 10),
    endsOn: DateTime(2027, 7, 24),
  );

  Matcher failsWith(StayErrorCode expected) =>
      throwsA(isA<StayException>().having((e) => e.code, 'code', expected));

  test('liste les séjours', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'stays': [stayJson],
      }),
    );

    final stays = await DioStayRepository(dioWith(adapter)).list();

    expect(stays.single.name, 'Été 2027');
    expect(stays.single.startsOn, DateTime.utc(2027, 7, 10));
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/admin/stays');
  });

  test('crée un séjour avec ses jours au format AAAA-MM-JJ', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(stayJson, status: 201),
    );

    final stay = await DioStayRepository(dioWith(adapter)).create(draft);

    expect(stay.id, '5d1e0000-0000-4000-8000-000000000001');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/api/admin/stays');
    expect(adapter.requests.single.data, {
      'name': 'Été 2027',
      'kind': 'acm',
      'starts_on': '2027-07-10',
      'ends_on': '2027-07-24',
    });
  });

  test('modifie un séjour sur sa route', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(stayJson));

    final stay = await DioStayRepository(
      dioWith(adapter),
    ).update('5d1e0000-0000-4000-8000-000000000001', draft);

    expect(stay.name, 'Été 2027');
    expect(adapter.requests.single.method, 'PUT');
    expect(
      adapter.requests.single.path,
      '/api/admin/stays/5d1e0000-0000-4000-8000-000000000001',
    );
    expect(adapter.requests.single.data, {
      'name': 'Été 2027',
      'kind': 'acm',
      'starts_on': '2027-07-10',
      'ends_on': '2027-07-24',
    });
  });

  test('traduit les codes d\'erreur de l\'API', () async {
    for (final (status, code, expected) in [
      (403, 'forbidden', StayErrorCode.forbidden),
      (400, 'invalid_stay_name', StayErrorCode.invalidName),
      (400, 'invalid_stay_kind', StayErrorCode.invalidKind),
      (400, 'invalid_stay_dates', StayErrorCode.invalidDates),
      (401, 'invalid_token', StayErrorCode.sessionExpired),
      (404, 'stay_not_found', StayErrorCode.notFound),
      (404, 'unknown_phone_number', StayErrorCode.unknownPhone),
      (409, 'not_an_acm_stay', StayErrorCode.notAcm),
      (409, 'already_director', StayErrorCode.alreadyDirector),
      (409, 'already_deputy', StayErrorCode.alreadyDeputy),
      (409, 'stay_has_team', StayErrorCode.hasTeam),
      (409, 'entries_outside_stay_dates', StayErrorCode.entriesOutsideDates),
      (400, 'invalid_user_name', StayErrorCode.invalidPersonName),
      (400, 'invalid_phone_format', StayErrorCode.invalidPhone),
      (500, 'boom', StayErrorCode.unknown),
    ]) {
      final adapter = FakeHttpAdapter(
        (_) =>
            FakeHttpAdapter.json({'error': '…', 'code': code}, status: status),
      );

      await expectLater(
        DioStayRepository(dioWith(adapter)).create(draft),
        failsWith(expected),
        reason: code,
      );
    }
  });

  test('reconnaît ce qui ne vient pas de l\'API', () async {
    await expectLater(
      DioStayRepository(
        dioWith(FakeHttpAdapter((_) => FakeHttpAdapter.html())),
      ).list(),
      failsWith(StayErrorCode.badServerUrl),
    );
    await expectLater(
      DioStayRepository(
        dioWith(
          FakeHttpAdapter(
            (_) => FakeHttpAdapter.json({
              'stays': [
                {...stayJson, 'kind': 'colo'},
              ],
            }),
          ),
        ),
      ).list(),
      failsWith(StayErrorCode.badServerUrl),
    );
  });

  test('sans réponse, c\'est le réseau', () async {
    final adapter = FakeHttpAdapter(
      (request) => throw DioException.connectionError(
        requestOptions: request,
        reason: 'injoignable',
      ),
    );

    await expectLater(
      DioStayRepository(dioWith(adapter)).list(),
      failsWith(StayErrorCode.network),
    );
  });

  test('pilote l\'équipe d\'un séjour sur ses routes', () async {
    const stay = '5d1e0000-0000-4000-8000-000000000001';
    const deputy = '0a5c0000-0000-4000-8000-000000000102';
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        ...stayJson,
        'directors': <Object?>[],
        'deputies': <Object?>[],
        'animators': <Object?>[],
        'can_manage_directors': true,
        'can_manage_deputies': true,
        'can_manage_animators': true,
      }),
    );
    final repository = DioStayRepository(dioWith(adapter));
    final phone = PhoneNumber.parse('06 33 33 33 33');

    await repository.get(stay);
    await repository.nameDirector(stay, phone);
    await repository.removeDirector(stay, deputy);
    await repository.addDeputy(stay, phone);
    await repository.removeDeputy(stay, deputy);
    await repository.addAnimator(stay, phone);
    await repository.removeAnimator(stay, deputy);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /api/stays/$stay',
      'POST /api/stays/$stay/directors',
      'DELETE /api/stays/$stay/directors/$deputy',
      'POST /api/stays/$stay/deputies',
      'DELETE /api/stays/$stay/deputies/$deputy',
      'POST /api/stays/$stay/animators',
      'DELETE /api/stays/$stay/animators/$deputy',
    ]);
    expect(adapter.requests[1].data, {'phone_number': '+33633333333'});
    expect(adapter.requests[5].data, {'phone_number': '+33633333333'});
  });

  test('ne demande de rétrograder que sur confirmation', () async {
    const stay = '5d1e0000-0000-4000-8000-000000000001';
    final adapter = FakeHttpAdapter(
      (request) => (request.data as Map<String, dynamic>)['demote'] == true
          ? FakeHttpAdapter.json({
              ...stayJson,
              'directors': <Object?>[],
              'deputies': <Object?>[],
              'animators': <Object?>[],
              'can_manage_directors': true,
              'can_manage_deputies': true,
              'can_manage_animators': true,
            })
          : FakeHttpAdapter.json({
              'error': 'Cette personne est adjointe du séjour.',
              'code': 'already_deputy',
            }, status: 409),
    );
    final repository = DioStayRepository(dioWith(adapter));
    final phone = PhoneNumber.parse('06 33 33 33 33');

    await expectLater(
      repository.addAnimator(stay, phone),
      failsWith(StayErrorCode.alreadyDeputy),
    );
    await repository.addAnimator(stay, phone, demote: true);

    expect(adapter.requests.last.data, {
      'phone_number': '+33633333333',
      'demote': true,
    });
  });

  test('liste les séjours du compte connecté', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'stays': [
          {...stayJson, 'role': 'deputy'},
        ],
      }),
    );

    final mine = await DioStayRepository(dioWith(adapter)).mine();

    expect(mine.single.stay.name, 'Été 2027');
    expect(adapter.requests.single.path, '/api/me/stays');
  });

  test('envoie les noms du compte à créer, s\'il y en a', () async {
    const stay = '5d1e0000-0000-4000-8000-000000000001';
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        ...stayJson,
        'directors': <Object?>[],
        'deputies': <Object?>[],
        'animators': <Object?>[],
        'can_manage_directors': true,
        'can_manage_deputies': true,
        'can_manage_animators': true,
      }),
    );
    final repository = DioStayRepository(dioWith(adapter));
    final phone = PhoneNumber.parse('07 11 22 33 44');

    await repository.addDeputy(
      stay,
      phone,
      newAccount: NewStaffAccount.parse(firstName: 'Lou', lastName: 'Petit'),
    );
    await repository.nameDirector(stay, phone);

    expect(adapter.requests[0].data, {
      'phone_number': '+33711223344',
      'first_name': 'Lou',
      'last_name': 'Petit',
    });
    expect(adapter.requests[1].data, {'phone_number': '+33711223344'});
  });
}
