import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.last_stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// La navigation de l'app : le séjour où elle s'ouvre, le tiroir du
/// téléphone et la barre latérale du grand écran. Dominique Durand dirige un
/// séjour d'été et anime un séjour de printemps, plus proche.
void main() {
  final year = DateTime.now().year + 1;
  final dominique = InMemoryAccountRepository.demoAccounts[1];
  final spring = Stay(
    id: '5d1e0000-0000-4000-8000-000000000011',
    name: 'Printemps — Vercors',
    kind: StayKind.acm,
    startsOn: DateTime.utc(year, 4, 12),
    endsOn: DateTime.utc(year, 4, 18),
  );
  final summer = Stay(
    id: '5d1e0000-0000-4000-8000-000000000012',
    name: 'Été — Pyrénées',
    kind: StayKind.acm,
    startsOn: DateTime.utc(year, 7, 10),
    endsOn: DateTime.utc(year, 7, 24),
  );

  late InMemoryLastStayRepository lastStay;

  Future<void> launchAs(
    WidgetTester tester,
    User user, {
    required Size size,
    InMemoryLastStayRepository? remembered,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    lastStay = remembered ?? InMemoryLastStayRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastStayRepositoryProvider.overrideWithValue(lastStay),
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
          stayRepositoryProvider.overrideWithValue(
            InMemoryStayRepository(
              stays: [spring, summer],
              staff: {
                spring.id: {dominique.id: StaffRole.animator},
                summer.id: {dominique.id: StaffRole.director},
              },
              viewer: () => (id: user.id, isAdmin: user.isAdmin),
            ),
          ),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  String appBarTitle(WidgetTester tester) =>
      (tester.widget<AppBar>(find.byType(AppBar).last).title as Text).data!;

  group('sur téléphone', () {
    const phone = Size(390, 844);

    testWidgets(
      'l\'app s\'ouvre sur le séjour le plus proche, et le tiroir mène aux '
      'autres',
      (tester) async {
        await launchAs(tester, dominique, size: phone);

        // Animateur au printemps : les nouvelles, pas l'équipe.
        expect(appBarTitle(tester), 'Printemps — Vercors');
        expect(find.byKey(const Key('newsModule')), findsOneWidget);
        expect(find.byKey(const Key('teamModule')), findsNothing);

        await tapKey(tester, 'menuButton');
        expect(find.text('À venir'), findsOneWidget);
        expect(find.byKey(const Key('adminSpace')), findsNothing);
        await tapKey(tester, 'myStay-${summer.id}');

        expect(appBarTitle(tester), 'Été — Pyrénées');
        expect(find.byKey(const Key('teamModule')), findsOneWidget);
        expect(await lastStay.read(dominique.id), summer.id);
      },
    );

    testWidgets('un module se referme par la flèche de retour', (tester) async {
      await launchAs(tester, dominique, size: phone);

      await tapKey(tester, 'newsModule');
      expect(appBarTitle(tester), 'Nouvelles');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(appBarTitle(tester), 'Printemps — Vercors');
    });

    testWidgets('l\'app rouvre le dernier séjour ouvert', (tester) async {
      await launchAs(
        tester,
        dominique,
        size: phone,
        remembered: InMemoryLastStayRepository({dominique.id: summer.id}),
      );

      expect(appBarTitle(tester), 'Été — Pyrénées');
    });
  });

  group('sur grand écran', () {
    const desktop = Size(1280, 800);

    testWidgets(
      'la barre latérale tient lieu de vue d\'ensemble, sans flèche de '
      'retour, et se replie',
      (tester) async {
        await launchAs(
          tester,
          dominique,
          size: desktop,
          remembered: InMemoryLastStayRepository({dominique.id: summer.id}),
        );

        // Le séjour s'ouvre sur son premier module, pas sur des tuiles.
        expect(appBarTitle(tester), 'Nouvelles');
        expect(find.byKey(const Key('menuButton')), findsNothing);

        await tapKey(tester, 'teamModule');
        expect(appBarTitle(tester), 'Équipe');
        expect(find.byType(BackButton), findsNothing);

        final logout = find.byKey(const Key('logoutButton'));
        final iconBefore = tester.getCenter(
          find.descendant(of: logout, matching: find.byType(Icon)),
        );
        expect(tester.getSize(logout).width, greaterThan(200));

        await tapKey(tester, 'toggleNav');
        // Repliée : l'entrée se réduit à son icône, qui n'a pas bougé.
        expect(tester.getSize(logout).width, lessThan(100));
        expect(
          tester.getCenter(
            find.descendant(of: logout, matching: find.byType(Icon)),
          ),
          iconBefore,
        );
      },
    );

    testWidgets('le sélecteur passe d\'un séjour à l\'autre', (tester) async {
      await launchAs(tester, dominique, size: desktop);

      await tapKey(tester, 'staySwitcher');
      await tapKey(tester, 'myStay-${summer.id}');

      expect(appBarTitle(tester), 'Nouvelles');
      expect(find.byKey(const Key('teamModule')), findsOneWidget);
    });
  });
}
