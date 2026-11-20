import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/news/dio.news.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  const stay = '5d1e0000-0000-4000-8000-000000000001';
  const photoJson = {
    'id': 'p1',
    'sorting': 'pending',
    'uploaded_at': '2027-07-12T12:00:00+00:00',
    'author': null,
    'mine': true,
    'day': null,
  };
  const dayJson = {
    'id': 'd1',
    'date': '2027-07-12',
    'summary': 'Rando',
    'status': 'draft',
    'publish_at': null,
    'photo_ids': <String>[],
    'updated_at': '2027-07-12T12:00:00+00:00',
  };

  Matcher failsWith(NewsErrorCode expected) =>
      throwsA(isA<NewsException>().having((e) => e.code, 'code', expected));

  test('liste les photos du séjour', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'photos': [photoJson],
      }),
    );

    final photos = await DioNewsRepository(dioWith(adapter)).photos(stay);

    expect(photos.single.id, 'p1');
    expect(adapter.requests.single.path, '/api/stays/$stay/photos');
  });

  test('dépose une photo en multipart, dans le champ photo', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(photoJson, status: 201),
    );

    await DioNewsRepository(dioWith(adapter)).upload(
      stay,
      PickedPhoto(name: 'lac.jpg', bytes: Uint8List.fromList([1, 2, 3])),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.data, isA<FormData>());
    final file = (request.data as FormData).files.single;
    expect(file.key, 'photo');
    expect(file.value.filename, 'lac.jpg');
  });

  test('trie une photo', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({...photoJson, 'sorting': 'kept'}),
    );

    final photo = await DioNewsRepository(
      dioWith(adapter),
    ).sort(stay, 'p1', PhotoSorting.kept);

    expect(photo.sorting, PhotoSorting.kept);
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, '/api/stays/$stay/photos/p1/sorting');
    expect(adapter.requests.single.data, {'sorting': 'kept'});
  });

  test('supprime une photo (204)', () async {
    final adapter = FakeHttpAdapter((_) => ResponseBody.fromString('', 204));

    await DioNewsRepository(dioWith(adapter)).deletePhoto(stay, 'p1');

    expect(adapter.requests.single.method, 'DELETE');
  });

  test('lit l\'image d\'une photo en octets, à la taille demandée', () async {
    final adapter = FakeHttpAdapter(
      (_) => ResponseBody.fromBytes(
        [137, 80, 78, 71],
        200,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      ),
    );

    final bytes = await DioNewsRepository(
      dioWith(adapter),
    ).image(stay, 'p1', PhotoSize.large);

    expect(bytes, [137, 80, 78, 71]);
    expect(adapter.requests.single.queryParameters, {'size': 'large'});
  });

  test('une image refusée se lit comme une erreur de l\'API', () async {
    final adapter = FakeHttpAdapter(
      (_) => ResponseBody.fromBytes(
        utf8.encode(jsonEncode({'error': '…', 'code': 'photo_not_found'})),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );

    await expectLater(
      DioNewsRepository(
        dioWith(adapter),
      ).image(stay, 'p1', PhotoSize.thumbnail),
      failsWith(NewsErrorCode.photoNotFound),
    );
  });

  test('crée un jour à sa date AAAA-MM-JJ', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(dayJson, status: 201),
    );

    await DioNewsRepository(
      dioWith(adapter),
    ).createDay(stay, DateTime.utc(2027, 7, 12));

    expect(adapter.requests.single.data, {'date': '2027-07-12', 'summary': ''});
  });

  test('publie tout de suite, ou programme à une heure donnée', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(dayJson));
    final repository = DioNewsRepository(dioWith(adapter));

    await repository.publishDay(stay, 'd1');
    await repository.publishDay(stay, 'd1', at: DateTime.utc(2027, 7, 12, 18));

    expect(adapter.requests[0].path, '/api/stays/$stay/days/d1/publication');
    expect(adapter.requests[0].data, <String, dynamic>{});
    expect(adapter.requests[1].data, {
      'publish_at': '2027-07-12T18:00:00.000Z',
    });
  });

  test('lit les nouvelles publiées', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'days': [
          {
            'id': 'd1',
            'date': '2027-07-12',
            'summary': 'Rando',
            'published_at': '2027-07-12T18:00:00+00:00',
            'photo_ids': ['p1'],
          },
        ],
      }),
    );

    final news = await DioNewsRepository(dioWith(adapter)).news(stay);

    expect(news.single.photoIds, ['p1']);
    expect(adapter.requests.single.path, '/api/stays/$stay/news');
  });

  test('traduit les codes d\'erreur de l\'API', () async {
    Future<void> expectCode(String code, NewsErrorCode expected) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({'error': '…', 'code': code}, status: 409),
      );
      await expectLater(
        DioNewsRepository(dioWith(adapter)).publishDay(stay, 'd1'),
        failsWith(expected),
      );
    }

    await expectCode('empty_day', NewsErrorCode.emptyDay);
    await expectCode('day_already_exists', NewsErrorCode.dayAlreadyExists);
    await expectCode('photo_in_another_day', NewsErrorCode.photoInAnotherDay);
    await expectCode('photo_storage_failed', NewsErrorCode.storageUnavailable);
    await expectCode('forbidden', NewsErrorCode.forbidden);
  });

  test('un corps qui n\'est pas de l\'API est un mauvais serveur', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.html());

    await expectLater(
      DioNewsRepository(dioWith(adapter)).photos(stay),
      failsWith(NewsErrorCode.badServerUrl),
    );
  });
}
