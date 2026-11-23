import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/in_memory.calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.last_stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// Le calendrier d'un séjour de bout en bout, en mémoire : l'été 2027 de
/// démo (10-24 juillet), dirigé par Dominique Durand, avec Sacha Bernard
/// pour animateur. Le petit-déjeuner y a lieu chaque jour.
void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';
  final dominique = InMemoryAccountRepository.demoAccounts[1];
  final sacha = InMemoryAccountRepository.demoAccounts[2];
  final staff = {
    summer: {dominique.id: StaffRole.director, sacha.id: StaffRole.animator},
  };

  late User viewer;
  late InMemoryCalendarRepository calendar;

  EntryDraft activity(String title, {int day = 11}) => EntryDraft(
    category: CalendarCategory.activity,
    details: EntryDetails(title: title),
    schedule: EntrySchedule(
      startsOn: DateTime.utc(2027, 7, day),
      endsOn: DateTime.utc(2027, 7, day),
      startTime: const ClockTime(14, 0),
      endTime: const ClockTime(16, 0),
    ),
  );

  /// Lance l'app pour [user], le calendrier déjà rempli par [seed] (au nom
  /// de qui il faut).
  Future<void> launchAs(
    WidgetTester tester,
    User user, {
    Future<void> Function()? seed,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    viewer = dominique;
    final stays = InMemoryStayRepository(
      staff: staff,
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
    );
    calendar = InMemoryCalendarRepository(
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
      roleOf: stays.roleIn,
      stayOf: stays.stayById,
      authorOf: (id) => switch (stays.accountById(id)) {
        final account? => SuggestionAuthor(
          id: account.id,
          firstName: account.firstName,
          lastName: account.lastName,
        ),
        null => null,
      },
    );
    await calendar.create(
      summer,
      EntryDraft(
        category: CalendarCategory.daily,
        details: const EntryDetails(title: 'Petit-déjeuner'),
        schedule: EntrySchedule(
          startsOn: DateTime.utc(2027, 7, 10),
          endsOn: DateTime.utc(2027, 7, 24),
          startTime: const ClockTime(8, 0),
          endTime: const ClockTime(9, 0),
          weekdays: const [1, 2, 3, 4, 5, 6, 7],
        ),
      ),
    );
    await seed?.call();
    viewer = user;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastStayRepositoryProvider.overrideWithValue(
            InMemoryLastStayRepository(),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)),
          sessionRepositoryProvider.overrideWithValue(
            InMemorySessionRepository(
              Session(
                token: 'in-memory-token',
                expiresAt: DateTime.now().add(const Duration(days: 1)),
                user: user,
              ),
            ),
          ),
          stayRepositoryProvider.overrideWithValue(stays),
          calendarRepositoryProvider.overrideWithValue(calendar),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'un animateur lit le calendrier et propose une activité, sans le modifier',
    (tester) async {
      await launchAs(tester, sacha);

      await tapKey(tester, 'calendarModule');
      expect(find.text('Samedi 10 juillet'), findsOneWidget);
      expect(find.text('Petit-déjeuner'), findsWidgets);
      expect(find.text('Mes suggestions'), findsOneWidget);

      await tapKey(tester, 'addEntryButton');
      expect(find.text('Proposer un événement'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('entryTitle')), 'Grand jeu');
      await tester.enterText(
        find.byKey(const Key('suggestionMessage')),
        'Dans les bois ?',
      );
      await tester.pump();
      await tapKey(tester, 'submitEntry');

      expect(find.text('Proposition envoyée à la direction.'), findsOneWidget);
      expect(find.text('Grand jeu'), findsNothing);

      await tapKey(tester, 'suggestionsTab');
      expect(find.text('Nouvel événement'), findsOneWidget);
      expect(find.byKey(const Key('status-pending')), findsOneWidget);
      expect(find.text('« Dans les bois ? »'), findsOneWidget);
      expect(find.byKey(const Key('acceptSuggestion')), findsNothing);

      await tapKey(tester, 'withdrawSuggestion');
      await tapKey(tester, 'confirmAction');
      expect(find.byKey(const Key('noSuggestions')), findsOneWidget);
    },
  );

  testWidgets(
    'la direction accepte la suggestion d\'un animateur : elle entre au '
    'calendrier',
    (tester) async {
      await launchAs(
        tester,
        dominique,
        seed: () async {
          viewer = sacha;
          await calendar.suggest(
            summer,
            kind: SuggestionKind.add,
            proposal: activity('Grand jeu'),
            message: 'Dans les bois ?',
          );
        },
      );

      await tapKey(tester, 'calendarModule');
      expect(find.text('Grand jeu'), findsNothing);
      await tapKey(tester, 'suggestionsTab');
      expect(find.textContaining('Par Sacha Bernard'), findsOneWidget);

      await tapKey(tester, 'acceptSuggestion');
      expect(find.text('Accepter la suggestion'), findsOneWidget);
      await tapKey(tester, 'submitEntry');
      expect(
        find.text('Suggestion acceptée : le calendrier est à jour.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('status-accepted')), findsOneWidget);

      await tapKey(tester, 'calendarTab');
      expect(find.text('Grand jeu'), findsOneWidget);
    },
  );

  testWidgets('la direction annule un jour d\'une série, puis le rétablit', (
    tester,
  ) async {
    await launchAs(tester, dominique);
    await tapKey(tester, 'calendarModule');

    final breakfast = (await calendar.entries(summer)).single.id;
    await tapKey(tester, 'occurrence-$breakfast');
    expect(
      find.text('Tous les jours, du 10 au 24 juillet 2027'),
      findsOneWidget,
    );
    await tapKey(tester, 'action-cancelDay');
    expect(find.text('Annulé le samedi 10 juillet.'), findsOneWidget);
    expect(find.text('Annulé ce jour'), findsOneWidget);
    expect(
      (await calendar.entries(summer)).single.changes.single.isCancelled,
      isTrue,
    );

    await tapKey(tester, 'occurrence-$breakfast');
    await tapKey(tester, 'action-restoreDay');
    expect(find.text('Annulé ce jour'), findsNothing);
    expect((await calendar.entries(summer)).single.changes, isEmpty);
  });
}
