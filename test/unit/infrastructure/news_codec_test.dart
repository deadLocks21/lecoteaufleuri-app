import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/news/news.codec.dart';

void main() {
  test('lit une photo, son auteur et le jour qu\'elle illustre', () {
    final photo = NewsCodec.photoFromJson({
      'id': '9b0f0000-0000-4000-8000-000000000001',
      'sorting': 'kept',
      'uploaded_at': '2027-07-12T12:00:00+00:00',
      'author': {'id': 'a', 'first_name': 'Charlie', 'last_name': 'Moreau'},
      'mine': false,
      'day': {'id': 'd', 'date': '2027-07-12'},
    });

    expect(photo.sorting, PhotoSorting.kept);
    expect(photo.uploadedAt, DateTime.utc(2027, 7, 12, 12));
    expect(photo.author?.lastName, 'Moreau');
    expect(photo.dayId, 'd');
    expect(photo.dayDate, DateTime.utc(2027, 7, 12));
  });

  test('une photo sans auteur ni jour', () {
    final photo = NewsCodec.photoFromJson({
      'id': 'p',
      'sorting': 'pending',
      'uploaded_at': '2027-07-12T12:00:00Z',
      'author': null,
      'mine': true,
      'day': null,
    });

    expect(photo.author, isNull);
    expect(photo.dayId, isNull);
    expect(photo.mine, isTrue);
  });

  test('lit un jour programmé, ses photos dans l\'ordre', () {
    final day = NewsCodec.dayFromJson({
      'id': 'd',
      'date': '2027-07-12',
      'summary': 'Rando',
      'status': 'scheduled',
      'publish_at': '2027-07-12T18:00:00+00:00',
      'photo_ids': ['b', 'a'],
      'updated_at': '2027-07-12T12:00:00+00:00',
    });

    expect(day.status, DayStatus.scheduled);
    expect(day.publishAt, DateTime.utc(2027, 7, 12, 18));
    expect(day.photoIds, ['b', 'a']);
  });

  test('lit un jour publié pour les lecteurs', () {
    final day = NewsCodec.publishedFromJson({
      'id': 'd',
      'date': '2027-07-12',
      'summary': '',
      'published_at': '2027-07-12T18:00:00+02:00',
      'photo_ids': ['a'],
    });

    expect(day.publishedAt, DateTime.utc(2027, 7, 12, 16));
    expect(day.date, DateTime.utc(2027, 7, 12));
  });

  test('refuse ce qui n\'a pas la forme attendue', () {
    expect(
      () => NewsCodec.photoFromJson({
        'id': 'p',
        'sorting': 'maybe',
        'uploaded_at': '2027-07-12T12:00:00Z',
        'mine': true,
      }),
      throwsFormatException,
    );
    expect(
      () => NewsCodec.dayFromJson({
        'id': 'd',
        'date': '12/07/2027',
        'summary': '',
        'status': 'draft',
        'photo_ids': [],
        'updated_at': '2027-07-12T12:00:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => NewsCodec.publishedFromJson('pas un jour'),
      throwsFormatException,
    );
  });

  test('envoie une heure en UTC', () {
    expect(
      NewsCodec.instantToJson(DateTime.utc(2027, 7, 12, 18, 30)),
      '2027-07-12T18:30:00.000Z',
    );
  });
}
