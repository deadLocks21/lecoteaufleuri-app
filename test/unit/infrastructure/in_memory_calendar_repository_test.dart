import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/in_memory.calendar.repository.dart';

void main() {
  const summer = 'summer';
  final stay = Stay(
    id: summer,
    name: 'Été 2027',
    kind: StayKind.acm,
    startsOn: DateTime.utc(2027, 7, 10),
    endsOn: DateTime.utc(2027, 7, 24),
  );
  const roles = {
    'director': StaffRole.director,
    'animator': StaffRole.animator,
    'other': StaffRole.animator,
  };

  late String viewer;
  late InMemoryCalendarRepository calendar;

  setUp(() {
    viewer = 'director';
    calendar = InMemoryCalendarRepository(
      viewer: () => (id: viewer, isAdmin: false),
      roleOf: (stayId, accountId) => stayId == summer ? roles[accountId] : null,
      stayOf: (stayId) => stayId == summer ? stay : null,
    );
  });

  Matcher failsWith(CalendarErrorCode expected) =>
      throwsA(isA<CalendarException>().having((e) => e.code, 'code', expected));

  EntryDraft pool({int from = 13, int to = 13}) => EntryDraft(
    category: CalendarCategory.activity,
    details: const EntryDetails(title: 'Piscine'),
    schedule: EntrySchedule(
      startsOn: DateTime.utc(2027, 7, from),
      endsOn: DateTime.utc(2027, 7, to),
      startTime: const ClockTime(10, 0),
      endTime: const ClockTime(12, 0),
      weekdays: from == to ? null : const [2, 4],
    ),
  );

  test('seule la direction compose, dans les dates du séjour', () async {
    await expectLater(
      calendar.create(summer, pool(from: 25, to: 25)),
      failsWith(CalendarErrorCode.invalidSchedule),
    );
    final entry = await calendar.create(summer, pool());
    expect(await calendar.entries(summer), hasLength(1));

    viewer = 'animator';
    await expectLater(
      calendar.delete(summer, entry.id),
      failsWith(CalendarErrorCode.forbidden),
    );
    viewer = 'stranger';
    await expectLater(
      calendar.entries(summer),
      failsWith(CalendarErrorCode.stayNotFound),
    );
  });

  test('un animateur propose, ne voit que ses suggestions, la direction '
      'les tranche', () async {
    final series = await calendar.create(summer, pool(from: 12, to: 23));

    viewer = 'animator';
    final cancel = await calendar.suggest(
      summer,
      kind: SuggestionKind.cancel,
      entryId: series.id,
      occurrenceDay: DateTime.utc(2027, 7, 22),
    );
    expect(cancel.targetTitle, 'Piscine');
    viewer = 'other';
    await calendar.suggest(summer, kind: SuggestionKind.add, proposal: pool());
    expect(await calendar.suggestions(summer), hasLength(1));
    await expectLater(
      calendar.withdraw(summer, cancel.id),
      failsWith(CalendarErrorCode.suggestionNotFound),
    );

    viewer = 'director';
    expect(await calendar.suggestions(summer), hasLength(2));
    await expectLater(
      calendar.withdraw(summer, cancel.id),
      failsWith(CalendarErrorCode.forbidden),
    );
    final accepted = await calendar.accept(summer, cancel.id);
    expect(accepted.status, SuggestionStatus.accepted);
    final entry = (await calendar.entries(summer)).single;
    expect(entry.changeOn(DateTime.utc(2027, 7, 22))?.isCancelled, isTrue);

    viewer = 'animator';
    await expectLater(
      calendar.withdraw(summer, cancel.id),
      failsWith(CalendarErrorCode.suggestionAlreadyDecided),
    );
  });

  test(
    'une suggestion de changement vise une occurrence de la série',
    () async {
      final series = await calendar.create(summer, pool(from: 12, to: 23));
      viewer = 'animator';

      await expectLater(
        calendar.suggest(
          summer,
          kind: SuggestionKind.change,
          entryId: series.id,
          occurrenceDay: DateTime.utc(2027, 7, 14),
          proposal: const OccurrenceDraft(details: EntryDetails(title: 'X')),
        ),
        failsWith(CalendarErrorCode.invalidOccurrenceDay),
      );
      await expectLater(
        calendar.suggest(
          summer,
          kind: SuggestionKind.change,
          entryId: series.id,
          occurrenceDay: DateTime.utc(2027, 7, 15),
          proposal: pool(),
        ),
        failsWith(CalendarErrorCode.invalidSuggestion),
      );
    },
  );

  test('chacun a son lien, que la régénération change', () async {
    final mine = await calendar.feed(summer);
    expect((await calendar.feed(summer)).url, mine.url);
    expect((await calendar.renewFeed(summer)).url, isNot(mine.url));
    viewer = 'animator';
    expect((await calendar.feed(summer)).url, isNot(mine.url));
  });
}
