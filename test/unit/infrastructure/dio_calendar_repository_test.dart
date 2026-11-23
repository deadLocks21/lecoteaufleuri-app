import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/dio.calendar.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  const stay = '5d1e0000-0000-4000-8000-000000000001';
  const entryJson = {
    'id': 'e1',
    'category': 'daily',
    'title': 'Petit-déjeuner',
    'place': 'Réfectoire',
    'notes': '',
    'starts_on': '2027-07-10',
    'ends_on': '2027-07-24',
    'start_time': '08:00',
    'end_time': '09:00',
    'weekdays': [1, 2, 3, 4, 5, 6, 7],
    'changes': [
      {
        'day': '2027-07-14',
        'cancelled': false,
        'title': 'Brunch',
        'place': '',
        'notes': '',
        'start_time': '10:00',
        'end_time': null,
      },
      {'day': '2027-07-15', 'cancelled': true},
    ],
    'updated_at': '2027-07-12T12:00:00+00:00',
  };

  Matcher failsWith(CalendarErrorCode expected) =>
      throwsA(isA<CalendarException>().having((e) => e.code, 'code', expected));

  test('lit les événements, séries et occurrences comprises', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'entries': [entryJson],
      }),
    );

    final entries = await DioCalendarRepository(dioWith(adapter)).entries(stay);

    expect(adapter.requests.single.path, '/api/stays/$stay/calendar');
    final entry = entries.single;
    expect(entry.schedule.weekdays, [1, 2, 3, 4, 5, 6, 7]);
    expect(entry.schedule.startTime, const ClockTime(8, 0));
    expect(entry.changes.first.draft?.details.title, 'Brunch');
    expect(entry.changes.last.isCancelled, isTrue);
    expect(entry.occurrences(), hasLength(14));
  });

  test('propose d\'annuler une occurrence, avec un mot', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'id': 's1',
        'kind': 'cancel',
        'status': 'pending',
        'entry_id': 'e1',
        'occurrence_day': '2027-07-15',
        'target_title': 'Petit-déjeuner',
        'proposal': null,
        'message': 'Grasse matinée',
        'response': '',
        'author': {'id': 'a1', 'first_name': 'Sacha', 'last_name': 'Bernard'},
        'mine': true,
        'created_at': '2027-07-12T12:00:00+00:00',
        'decided_at': null,
      }, status: 201),
    );

    final suggestion = await DioCalendarRepository(dioWith(adapter)).suggest(
      stay,
      kind: SuggestionKind.cancel,
      entryId: 'e1',
      occurrenceDay: DateTime.utc(2027, 7, 15),
      message: 'Grasse matinée',
    );

    final request = adapter.requests.single;
    expect(request.path, '/api/stays/$stay/calendar/suggestions');
    expect(jsonDecode(jsonEncode(request.data)), {
      'kind': 'cancel',
      'entry_id': 'e1',
      'occurrence_day': '2027-07-15',
      'message': 'Grasse matinée',
    });
    expect(suggestion.occurrenceDay, DateTime.utc(2027, 7, 15));
    expect(suggestion.author?.firstName, 'Sacha');
  });

  test('envoie un événement sous la forme de l\'API', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(entryJson, status: 201),
    );

    await DioCalendarRepository(dioWith(adapter)).create(
      stay,
      EntryDraft(
        category: CalendarCategory.activity,
        details: const EntryDetails(title: 'Mini-camp'),
        schedule: EntrySchedule(
          startsOn: DateTime.utc(2027, 7, 20),
          endsOn: DateTime.utc(2027, 7, 22),
        ),
      ),
    );

    expect(jsonDecode(jsonEncode(adapter.requests.single.data)), {
      'category': 'activity',
      'title': 'Mini-camp',
      'place': '',
      'notes': '',
      'starts_on': '2027-07-20',
      'ends_on': '2027-07-22',
      'start_time': null,
      'end_time': null,
      'weekdays': null,
    });
  });

  test('le lien d\'abonnement part de l\'adresse de l\'API', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({'path': '/api/feeds/abc.ics'}),
    );

    final feed = await DioCalendarRepository(dioWith(adapter)).feed(stay);

    expect(feed.url.toString(), 'http://api.test/api/feeds/abc.ics');
    expect(adapter.requests.single.path, '/api/stays/$stay/calendar/feed');
  });

  test('traduit les erreurs de l\'API', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'error': 'Interdit',
        'code': 'forbidden',
      }, status: 403),
    );
    final repository = DioCalendarRepository(dioWith(adapter));

    await expectLater(
      repository.delete(stay, 'e1'),
      failsWith(CalendarErrorCode.forbidden),
    );

    adapter.respond = (_) => FakeHttpAdapter.json({
      'error': 'Déjà tranchée',
      'code': 'suggestion_already_decided',
    }, status: 409);
    await expectLater(
      repository.withdraw(stay, 's1'),
      failsWith(CalendarErrorCode.suggestionAlreadyDecided),
    );

    adapter.respond = (_) => FakeHttpAdapter.html();
    await expectLater(
      repository.entries(stay),
      failsWith(CalendarErrorCode.badServerUrl),
    );
  });
}
