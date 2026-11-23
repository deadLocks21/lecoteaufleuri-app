import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/in_memory.calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.repository_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_days.page.dart';

/// Le bandeau des jours ne sert qu'à choisir ceux qu'on affiche : quand tout
/// le séjour tient à l'écran, il s'efface.
void main() {
  const director = 'director';

  Future<void> show(WidgetTester tester, StayDto stay, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calendar = InMemoryCalendarRepository(
      viewer: () => (id: director, isAdmin: false),
      roleOf: (_, _) => StaffRole.director,
      stayOf: (_) => Stay(
        id: stay.id,
        name: stay.name,
        kind: stay.kind,
        startsOn: stay.startsOn,
        endsOn: stay.endsOn,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [calendarRepositoryProvider.overrideWithValue(calendar)],
        child: MaterialApp(home: CalendarDaysPage(stay: stay, direction: true)),
      ),
    );
    await tester.pumpAndSettle();
  }

  StayDto stay(int days) => StayDto(
    id: 'stay',
    name: 'Séjour',
    kind: StayKind.other,
    startsOn: DateTime.utc(2027, 3, 13),
    endsOn: DateTime.utc(2027, 3, 12 + days),
  );

  testWidgets('un week-end sur grand écran : pas de choix des jours', (
    tester,
  ) async {
    await show(tester, stay(2), 1280);
    expect(find.byKey(const Key('previousDays')), findsNothing);
    expect(find.byKey(const Key('strip-13-3')), findsNothing);
    expect(find.byKey(const Key('timeGrid')), findsOneWidget);
  });

  testWidgets('le même week-end sur téléphone : un jour à la fois, à choisir', (
    tester,
  ) async {
    await show(tester, stay(2), 400);
    expect(find.byKey(const Key('previousDays')), findsOneWidget);
    expect(find.byKey(const Key('strip-14-3')), findsOneWidget);
  });

  testWidgets('deux semaines sur grand écran : le choix des jours reste', (
    tester,
  ) async {
    await show(tester, stay(15), 1280);
    expect(find.byKey(const Key('previousDays')), findsOneWidget);
  });
}
