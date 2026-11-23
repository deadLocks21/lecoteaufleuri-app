import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/day_layout.dart';

void main() {
  final day = DateTime.utc(2027, 7, 12);

  CalendarOccurrenceDto at(
    String id,
    ClockTime? start, [
    ClockTime? end,
    DateTime? endsOn,
  ]) => CalendarOccurrenceDto(
    entryId: id,
    category: CalendarCategory.daily,
    title: id,
    startsOn: day,
    endsOn: endsOn ?? day,
    startTime: start,
    endTime: end,
    recurring: false,
  );

  ClockTime h(int hour, [int minute = 0]) => ClockTime(hour, minute);

  /// Chaque occurrence : début, fin, voie, voies, crans de décalage.
  Map<String, (int, int, int, int, int)> layout(
    List<CalendarOccurrenceDto> all,
  ) => {
    for (final placed in layoutDay(all))
      placed.occurrence.entryId: (
        placed.start,
        placed.end,
        placed.lane,
        placed.lanes,
        placed.indent,
      ),
  };

  test('ce qui ne se chevauche pas prend toute la largeur', () {
    expect(
      layout([at('déjeuner', h(12), h(13)), at('goûter', h(16, 30), h(17))]),
      {'déjeuner': (720, 780, 0, 1, 0), 'goûter': (990, 1020, 0, 1, 0)},
    );
  });

  test('un court événement pendant un long se pose dessus, décalé, sans '
      'réduire le long', () {
    expect(
      layout([at('activité', h(12, 30), h(17)), at('goûter', h(16, 30))]),
      {'activité': (750, 1020, 0, 1, 0), 'goûter': (990, 1005, 0, 1, 1)},
    );
  });

  test('ce qui commence presque ensemble se met côte à côte', () {
    expect(
      layout([
        at('court', h(14), h(15)),
        at('long', h(14), h(17)),
        at('médecin', h(14, 20), h(15)),
      ]),
      {
        // À même heure, le plus long prend la première voie.
        'long': (840, 1020, 0, 3, 0),
        'court': (840, 900, 1, 3, 0),
        'médecin': (860, 900, 2, 3, 0),
      },
    );
  });

  test('côte à côte, eux aussi, sur un plus long commencé avant', () {
    expect(
      layout([
        at('journée', h(9), h(17)),
        at('atelier', h(14), h(15)),
        at('rendez-vous', h(14, 10), h(14, 40)),
        at('goûter', h(16, 30), h(17)),
      ]),
      {
        'journée': (540, 1020, 0, 1, 0),
        'atelier': (840, 900, 0, 2, 1),
        'rendez-vous': (850, 880, 1, 2, 1),
        'goûter': (990, 1020, 0, 1, 1),
      },
    );
  });

  test('on dessine d\'abord ce sur quoi les autres se posent', () {
    final order = [
      for (final placed in layoutDay([
        at('goûter', h(16, 30)),
        at('veillée', h(20), h(21)),
        at('activité', h(12, 30), h(17)),
      ]))
        placed.occurrence.entryId,
    ];
    expect(order, ['activité', 'veillée', 'goûter']);
  });

  test(
    'sans heure de fin, un quart d\'heure qui laisse la place à la suite',
    () {
      expect(
        layout([at('lever', h(7, 45)), at('petit-déjeuner', h(8), h(9))]),
        {'lever': (465, 480, 0, 1, 0), 'petit-déjeuner': (480, 540, 0, 1, 0)},
      );
    },
  );

  test('le décalage s\'arrête à quelques crans', () {
    final placed = layout([
      for (var i = 0; i < 6; i++) at('e$i', h(9 + i), h(20)),
    ]);
    expect([for (var i = 0; i < 6; i++) placed['e$i']!.$5], [0, 1, 2, 3, 3, 3]);
  });

  test('la journée et les jours multiples vont dans le bandeau', () {
    expect(isTimedOn(at('lever', h(7, 45)), day), isTrue);
    expect(isTimedOn(at('sortie', null), day), isFalse);
    expect(
      isTimedOn(at('camp', h(10), h(16), DateTime.utc(2027, 7, 14)), day),
      isFalse,
    );
    expect(
      isTimedOn(at('lever', h(7, 45)), DateTime.utc(2027, 7, 13)),
      isFalse,
    );
  });

  test('un créneau se choisit au quart d\'heure près', () {
    // 10 h 07 tombe dans le quart d'heure de 10 h ; 10 h 15 dans le suivant.
    expect(quarterAt(607), 600);
    expect(quarterAt(615), 615);
    expect(quarterAt(-5), 0);
    expect(quarterAt(1500), minutesPerDay - slotMinutes);
  });

  test('un glisser couvre les quarts d\'heure balayés, dans un sens ou '
      'l\'autre', () {
    expect(sweptSlot(615, 675), (start: 615, end: 690));
    expect(sweptSlot(930, 840), (start: 840, end: 945));
    expect(sweptSlot(600, 600), (start: 600, end: 615));
  });

  test('un clic donne une heure, sans passer minuit', () {
    expect(clickedSlot(615), (start: 615, end: 675));
    expect(clickedSlot(23 * 60 + 30), (start: 1410, end: minutesPerDay));
    expect(clockAt(615), const ClockTime(10, 15));
    expect(clockAt(minutesPerDay), const ClockTime(23, 59));
  });
}
