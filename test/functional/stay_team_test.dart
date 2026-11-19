import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// La direction d'un séjour de bout en bout, en mémoire. Séjours de démo :
/// « Été 2027 — Pyrénées » (ACM, dirigé par Dominique Durand) et « Week-end
/// des animateurs » (hors ACM). Comptes de démo : Camille Démo (admin),
/// Dominique Durand (06 22 22 22 22), Sacha Bernard (06 33 33 33 33).
void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';
  const weekend = '5d1e0000-0000-4000-8000-000000000002';
  const dominiqueId = '0a5c0000-0000-4000-8000-000000000101';
  const sachaId = '0a5c0000-0000-4000-8000-000000000102';
  final demo = InMemoryAuthRepository.demoUser;
  final dominique = InMemoryAccountRepository.demoAccounts[1];
  final sacha = InMemoryAccountRepository.demoAccounts[2];

  /// Lance l'app connectée en [user] ; le dépôt des séjours tire ses droits
  /// de ce compte, comme l'API de l'appelant.
  Future<void> launchAs(
    WidgetTester tester,
    User user, {
    Map<String, Map<String, StaffRole>>? staff,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
              staff: staff,
              viewer: () => (id: user.id, isAdmin: user.isAdmin),
            ),
          ),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openStayAsAdmin(WidgetTester tester, String stayId) async {
    await tester.tap(find.byKey(const Key('staysSpace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('stay-$stayId')));
    await tester.pumpAndSettle();
  }

  Future<void> nameByPhone(WidgetTester tester, String phone) async {
    await tester.enterText(find.byKey(const Key('staffPhoneField')), phone);
    await tester.tap(find.byKey(const Key('nameStaffButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('l\'admin voit la direction d\'un séjour ACM', (tester) async {
    await launchAs(tester, demo);
    await openStayAsAdmin(tester, summer);

    expect(find.text('Du 10 au 24 juillet 2027'), findsOneWidget);
    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.byKey(const Key('noDeputies')), findsOneWidget);
    expect(find.byKey(const Key('nameDirectorButton')), findsOneWidget);
    expect(find.byKey(const Key('addDeputyButton')), findsOneWidget);
  });

  testWidgets('un séjour hors ACM n\'a pas de direction', (tester) async {
    await launchAs(tester, demo);
    await openStayAsAdmin(tester, weekend);

    expect(find.byKey(const Key('noDirection')), findsOneWidget);
    expect(find.byKey(const Key('nameDirectorButton')), findsNothing);
  });

  testWidgets(
    'l\'admin change de directeur en choisissant un compte dans la liste',
    (tester) async {
      await launchAs(tester, demo);
      await openStayAsAdmin(tester, summer);

      await tester.tap(find.byKey(const Key('nameDirectorButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('staffSearchField')),
        'bernard',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('pickAccount-$sachaId')));
      await tester.pumpAndSettle();

      expect(find.text('Directeur nommé.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('directorTile')),
          matching: find.text('Sacha Bernard'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('l\'admin ajoute un adjoint par son numéro, puis le retire', (
    tester,
  ) async {
    await launchAs(tester, demo);
    await openStayAsAdmin(tester, summer);

    await tester.tap(find.byKey(const Key('addDeputyButton')));
    await tester.pumpAndSettle();
    await nameByPhone(tester, '06 33 33 33 33');

    expect(find.text('Adjoint ajouté.'), findsOneWidget);
    expect(find.byKey(const Key('deputy-$sachaId')), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeDeputy-$sachaId')));
    await tester.pumpAndSettle();
    expect(find.text('Retirer cet adjoint ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('Adjoint retiré.'), findsOneWidget);
    expect(find.byKey(const Key('deputy-$sachaId')), findsNothing);
  });

  testWidgets(
    'un numéro sans compte, ou celui du directeur, est refusé sur le champ',
    (tester) async {
      await launchAs(tester, demo);
      await openStayAsAdmin(tester, summer);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();

      await nameByPhone(tester, '06 99 99 99 99');
      expect(find.text('Aucun compte pour ce numéro.'), findsOneWidget);

      await nameByPhone(tester, '06 22 22 22 22');
      expect(
        find.text('Cette personne dirige déjà le séjour.'),
        findsOneWidget,
      );

      await nameByPhone(tester, '01 23');
      expect(
        find.text('Numéro de mobile invalide (ex. 06 12 34 56 78).'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'le directeur retrouve son séjour à l\'accueil et y nomme un adjoint par '
    'son numéro, sans voir les comptes',
    (tester) async {
      await launchAs(tester, dominique);

      expect(find.byKey(const Key('staysSpace')), findsNothing);
      expect(find.text('Directeur · Du 10 au 24 juillet 2027'), findsOneWidget);

      await tester.tap(find.byKey(const Key('myStay-$summer')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nameDirectorButton')), findsNothing);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffSearchField')), findsNothing);

      await nameByPhone(tester, '06 33 33 33 33');

      expect(find.text('Adjoint ajouté.'), findsOneWidget);
      expect(find.byKey(const Key('deputy-$sachaId')), findsOneWidget);
    },
  );

  testWidgets('un adjoint voit la direction sans pouvoir la changer', (
    tester,
  ) async {
    await launchAs(
      tester,
      sacha,
      staff: {
        summer: {dominiqueId: StaffRole.director, sachaId: StaffRole.deputy},
      },
    );

    expect(find.text('Adjoint · Du 10 au 24 juillet 2027'), findsOneWidget);
    await tester.tap(find.byKey(const Key('myStay-$summer')));
    await tester.pumpAndSettle();

    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.byKey(const Key('nameDirectorButton')), findsNothing);
    expect(find.byKey(const Key('addDeputyButton')), findsNothing);
    expect(find.byKey(const Key('removeDeputy-$sachaId')), findsNothing);
  });

  testWidgets('l\'admin qui se nomme adjoint retrouve le séjour à l\'accueil', (
    tester,
  ) async {
    await launchAs(tester, demo);
    expect(find.byKey(const Key('myStay-$summer')), findsNothing);

    await openStayAsAdmin(tester, summer);
    await tester.tap(find.byKey(const Key('addDeputyButton')));
    await tester.pumpAndSettle();
    await nameByPhone(tester, '06 12 34 56 78');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Adjoint · Du 10 au 24 juillet 2027'), findsOneWidget);
  });
}
