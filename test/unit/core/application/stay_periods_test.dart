import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/stay_periods.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

MyStayDto _stay(String id, DateTime startsOn, DateTime endsOn) => MyStayDto(
  stay: StayDto(
    id: id,
    name: id,
    kind: StayKind.acm,
    startsOn: startsOn,
    endsOn: endsOn,
  ),
  role: StaffRole.director,
);

void main() {
  final today = DateTime.utc(2026, 11, 20);
  final pastOld = _stay(
    'past-old',
    DateTime.utc(2026, 7, 1),
    DateTime.utc(2026, 7, 14),
  );
  final pastRecent = _stay(
    'past-recent',
    DateTime.utc(2026, 10, 19),
    DateTime.utc(2026, 10, 30),
  );
  final currentLong = _stay(
    'current-long',
    DateTime.utc(2026, 11, 1),
    DateTime.utc(2026, 12, 20),
  );
  final currentShort = _stay(
    'current-short',
    DateTime.utc(2026, 11, 18),
    DateTime.utc(2026, 11, 20),
  );
  final upcomingFar = _stay(
    'upcoming-far',
    DateTime.utc(2027, 2, 13),
    DateTime.utc(2027, 2, 20),
  );
  final upcomingNear = _stay(
    'upcoming-near',
    DateTime.utc(2026, 11, 28),
    DateTime.utc(2026, 11, 29),
  );

  group('stayPeriod', () {
    test('un séjour est en cours du premier au dernier jour compris', () {
      expect(stayPeriod(currentShort.stay, today), StayPeriod.current);
      expect(
        stayPeriod(currentShort.stay, DateTime.utc(2026, 11, 18)),
        StayPeriod.current,
      );
      expect(
        stayPeriod(currentShort.stay, DateTime.utc(2026, 11, 17)),
        StayPeriod.upcoming,
      );
      expect(
        stayPeriod(currentShort.stay, DateTime.utc(2026, 11, 21)),
        StayPeriod.past,
      );
    });
  });

  group('staysByPeriod', () {
    test('range chaque période dans l\'ordre où on y cherche', () {
      final grouped = staysByPeriod([
        pastOld,
        upcomingFar,
        currentLong,
        pastRecent,
        upcomingNear,
        currentShort,
      ], today);

      expect(grouped[StayPeriod.current], [currentShort, currentLong]);
      expect(grouped[StayPeriod.upcoming], [upcomingNear, upcomingFar]);
      expect(grouped[StayPeriod.past], [pastRecent, pastOld]);
    });

    test('toutes les périodes sont présentes, même vides', () {
      expect(staysByPeriod(const [], today), {
        StayPeriod.current: isEmpty,
        StayPeriod.upcoming: isEmpty,
        StayPeriod.past: isEmpty,
      });
    });
  });

  group('defaultStay', () {
    final all = [pastRecent, currentLong, currentShort, upcomingNear];

    test('le dernier ouvert, s\'il n\'est pas terminé', () {
      expect(
        defaultStay(all, lastOpenedId: upcomingNear.stay.id, today: today),
        upcomingNear,
      );
    });

    test('sinon celui en cours qui finit le plus tôt', () {
      expect(
        defaultStay(all, lastOpenedId: pastRecent.stay.id, today: today),
        currentShort,
      );
      expect(
        defaultStay(all, lastOpenedId: 'inconnu', today: today),
        currentShort,
      );
    });

    test('sinon le prochain, puis le dernier passé', () {
      expect(
        defaultStay([pastRecent, upcomingFar, upcomingNear], today: today),
        upcomingNear,
      );
      expect(defaultStay([pastOld, pastRecent], today: today), pastRecent);
    });

    test('aucun sans séjour', () {
      expect(defaultStay(const [], lastOpenedId: 'x', today: today), isNull);
    });
  });
}
