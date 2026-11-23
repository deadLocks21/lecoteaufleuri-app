import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

/// Les suggestions en attente posées dans le calendrier : là où elles
/// placeraient (ou retireraient) quelque chose.
void main() {
  DateTime day(int d) => DateTime.utc(2027, 7, d);
  final breakfast = CalendarEntryDto(
    id: 'breakfast',
    draft: EntryDraftDto(
      category: CalendarCategory.daily,
      title: 'Petit-déjeuner',
      startsOn: day(10),
      endsOn: day(24),
      startTime: const ClockTime(8, 0),
      endTime: const ClockTime(9, 0),
      weekdays: const [1, 2, 3, 4, 5, 6, 7],
    ),
    updatedAt: day(1),
  );
  final calendar = StayCalendarDto([breakfast]);

  CalendarSuggestionDto suggestion(
    SuggestionKind kind, {
    SuggestionStatus status = SuggestionStatus.pending,
    String? entryId,
    DateTime? occurrenceDay,
    EntryDraftDto? entry,
    OccurrenceDraftDto? occurrence,
  }) => CalendarSuggestionDto(
    id: 's',
    kind: kind,
    status: status,
    entryId: entryId,
    occurrenceDay: occurrenceDay,
    entryProposal: entry,
    occurrenceProposal: occurrence,
    mine: false,
    createdAt: day(1),
  );

  test('un ajout se pose à ses jours, et seulement en attente', () {
    final add = suggestion(
      SuggestionKind.add,
      entry: EntryDraftDto(
        category: CalendarCategory.activity,
        title: 'Grand jeu',
        startsOn: day(11),
        endsOn: day(11),
        startTime: const ClockTime(14, 0),
      ),
    );
    expect(calendar.suggestedOn(day(10), [add]), isEmpty);
    final placed = calendar.suggestedOn(day(11), [add]).single;
    expect(placed.suggestion, same(add));
    expect(placed.occurrence.title, 'Grand jeu');

    final declined = suggestion(
      SuggestionKind.add,
      status: SuggestionStatus.declined,
      entry: add.entryProposal,
    );
    expect(calendar.suggestedOn(day(11), [declined]), isEmpty);
  });

  test('un jour changé se pose ce jour-là, tel que proposé', () {
    final change = suggestion(
      SuggestionKind.change,
      entryId: 'breakfast',
      occurrenceDay: day(12),
      occurrence: const OccurrenceDraftDto(
        title: 'Brunch',
        startTime: ClockTime(10, 0),
      ),
    );
    expect(calendar.suggestedOn(day(11), [change]), isEmpty);
    final placed = calendar.suggestedOn(day(12), [change]).single.occurrence;
    expect(placed.title, 'Brunch');
    expect(placed.startTime, const ClockTime(10, 0));
    expect(placed.category, CalendarCategory.daily);
  });

  test('une annulation de la série se pose sur chacun de ses jours', () {
    final cancel = suggestion(SuggestionKind.cancel, entryId: 'breakfast');
    for (final d in [10, 17, 24]) {
      expect(
        calendar.suggestedOn(day(d), [cancel]).single.occurrence.title,
        'Petit-déjeuner',
      );
    }
  });
}
