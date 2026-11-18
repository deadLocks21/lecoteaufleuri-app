import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
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

  test('traduit les codes d\'erreur de l\'API', () async {
    for (final (status, code, expected) in [
      (403, 'forbidden', StayErrorCode.forbidden),
      (400, 'invalid_stay_name', StayErrorCode.invalidName),
      (400, 'invalid_stay_kind', StayErrorCode.invalidKind),
      (400, 'invalid_stay_dates', StayErrorCode.invalidDates),
      (401, 'invalid_token', StayErrorCode.sessionExpired),
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
}
