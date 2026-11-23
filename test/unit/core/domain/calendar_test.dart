import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

void main() {
  DateTime day(int d) => DateTime.utc(2027, 7, d);

  CalendarEntry entry({
    String id = 'e1',
    String title = 'Petit-déjeuner',
    int from = 12,
    int to = 16,
    ClockTime? start = const ClockTime(8, 0),
    ClockTime? end = const ClockTime(9, 0),
    List<int>? weekdays = const [1, 2, 3, 4, 5],
    List<OccurrenceChange> changes = const [],
  }) => CalendarEntry(
    id: id,
    category: CalendarCategory.daily,
    details: EntryDetails(title: title),
    schedule: EntrySchedule(
      startsOn: day(from),
      endsOn: day(to),
      startTime: start,
      endTime: end,
      weekdays: weekdays,
    ),
    changes: changes,
    updatedAt: DateTime.utc(2027),
  );

  test('une série a lieu chacun de ses jours de la semaine', () {
    // Du lundi 12 au dimanche 18 juillet 2027, les mardis et jeudis.
    final schedule = EntrySchedule(
      startsOn: day(12),
      endsOn: day(18),
      weekdays: const [4, 2],
    );

    expect(schedule.days, [day(13), day(15)]);
    expect(schedule.weekdays, [2, 4]);
    expect(schedule.hasOccurrenceOn(day(15)), isTrue);
    expect(schedule.hasOccurrenceOn(day(16)), isFalse);
  });

  test('une occurrence modifiée ou annulée s\'écarte de sa série', () {
    final breakfast = entry(
      changes: [
        OccurrenceChange(
          day: day(14),
          draft: const OccurrenceDraft(
            details: EntryDetails(title: 'Brunch'),
            startTime: ClockTime(10, 0),
          ),
        ),
        OccurrenceChange(day: day(15)),
      ],
    );

    final occurrences = breakfast.occurrences();
    expect([for (final o in occurrences) o.startsOn.day], [12, 13, 14, 16]);
    final brunch = occurrences[2];
    expect(
      [brunch.details.title, brunch.startTime, brunch.endTime],
      ['Brunch', const ClockTime(10, 0), null],
    );
    expect(brunch.changed, isTrue);

    // La direction voit aussi le jour annulé, pour le rétablir.
    final all = breakfast.occurrences(withCancelled: true);
    expect(all.where((o) => o.cancelled).single.startsOn, day(15));
  });

  test('un jour se lit à la journée d\'abord, puis par heure', () {
    final camp = CalendarEntry(
      id: 'camp',
      category: CalendarCategory.activity,
      details: const EntryDetails(title: 'Mini-camp'),
      schedule: EntrySchedule(startsOn: day(13), endsOn: day(15)),
      updatedAt: DateTime.utc(2027),
    );
    final entries = [
      entry(id: 'dinner', title: 'Dîner', start: const ClockTime(19, 0)),
      entry(),
      camp,
    ];

    expect(
      [for (final o in occurrencesOn(entries, day(14))) o.entryId],
      ['camp', 'e1', 'dinner'],
    );
    expect(occurrencesOn(entries, day(12)).map((o) => o.entryId), [
      'e1',
      'dinner',
    ]);
  });

  test(
    'il dit ce qui empêche des dates et des heures de faire un événement',
    () {
      EntrySchedule schedule({
        int to = 12,
        ClockTime? start,
        ClockTime? end,
        List<int>? weekdays,
      }) => EntrySchedule(
        startsOn: day(12),
        endsOn: day(to),
        startTime: start,
        endTime: end,
        weekdays: weekdays,
      );

      expect(schedule().problem, isNull);
      expect(
        schedule(end: const ClockTime(9, 0)).problem,
        ScheduleProblem.endWithoutStart,
      );
      expect(
        schedule(
          start: const ClockTime(9, 0),
          end: const ClockTime(8, 0),
        ).problem,
        ScheduleProblem.endBeforeStart,
      );
      expect(
        schedule(to: 14, start: const ClockTime(9, 0)).problem,
        ScheduleProblem.severalDaysWithoutEnd,
      );
      expect(
        schedule(
          to: 14,
          start: const ClockTime(9, 0),
          end: const ClockTime(8, 0),
        ).problem,
        isNull,
      );
      expect(schedule(weekdays: const []).problem, ScheduleProblem.noWeekday);
      expect(
        schedule(to: 13, weekdays: const [5]).problem,
        ScheduleProblem.noDay,
      );
    },
  );

  test('le lien d\'abonnement s\'ouvre sur iPhone et dans Google Agenda', () {
    final feed = CalendarFeed(Uri.parse('https://api.test/api/feeds/abc.ics'));

    expect(feed.webcal.toString(), 'webcal://api.test/api/feeds/abc.ics');
    expect(feed.googleCalendar.host, 'calendar.google.com');
    expect(
      feed.googleCalendar.queryParameters['cid'],
      'webcal://api.test/api/feeds/abc.ics',
    );
  });

  test('une heure se lit et s\'écrit en HH:MM', () {
    expect(ClockTime.parse('07:05').format(), '07:05');
    expect(() => ClockTime.parse('24:00'), throwsFormatException);
    expect(() => ClockTime.parse('7:05'), throwsFormatException);
  });
}
