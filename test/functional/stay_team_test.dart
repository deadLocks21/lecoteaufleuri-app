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
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.last_stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// L'équipe d'un séjour de bout en bout, en mémoire. Séjours de démo :
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
    // Un grand écran haut : barre latérale dépliée, listes entières.
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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

  /// Un texte du sélecteur de séjour, en tête de la barre latérale.
  Finder inSwitcher(String text) => find.descendant(
    of: find.byKey(const Key('staySwitcher')),
    matching: find.text(text),
  );

  /// Ouvre le module Équipe du séjour où l'app s'est ouverte.
  Future<void> openTeam(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('teamModule')));
    await tester.pumpAndSettle();
  }

  /// Ouvre un séjour depuis l'administration, puis son équipe si [team].
  Future<void> openStayAsAdmin(
    WidgetTester tester,
    String stayId, {
    bool team = true,
  }) async {
    await tester.tap(find.byKey(const Key('staysSpace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('stay-$stayId')));
    await tester.pumpAndSettle();
    if (team) await openTeam(tester);
  }

  Future<void> nameByPhone(WidgetTester tester, String phone) async {
    await tester.enterText(find.byKey(const Key('staffPhoneField')), phone);
    await tester.tap(find.byKey(const Key('nameStaffButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('l\'admin voit la direction d\'un séjour ACM', (tester) async {
    await launchAs(tester, demo);
    await openStayAsAdmin(tester, summer, team: false);

    expect(inSwitcher('Du 10 au 24 juillet 2027'), findsOneWidget);
    expect(inSwitcher('Administration'), findsOneWidget);
    await openTeam(tester);
    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.byKey(const Key('noDeputies')), findsOneWidget);
    expect(find.byKey(const Key('addDirectorButton')), findsOneWidget);
    expect(find.byKey(const Key('addDeputyButton')), findsOneWidget);
    expect(find.byKey(const Key('noAnimators')), findsOneWidget);
    expect(find.byKey(const Key('addAnimatorButton')), findsOneWidget);
  });

  testWidgets('un séjour hors ACM n\'a pas de direction', (tester) async {
    await launchAs(tester, demo);
    await openStayAsAdmin(tester, weekend, team: false);

    expect(find.byKey(const Key('newsModule')), findsOneWidget);
    expect(find.byKey(const Key('teamModule')), findsNothing);
  });

  testWidgets(
    'l\'admin ajoute un second directeur en choisissant un compte, puis '
    'retire le premier',
    (tester) async {
      await launchAs(tester, demo);
      await openStayAsAdmin(tester, summer);

      await tester.tap(find.byKey(const Key('addDirectorButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('staffSearchField')),
        'bernard',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('pickAccount-$sachaId')));
      await tester.pumpAndSettle();

      expect(find.text('Directeur ajouté.'), findsOneWidget);
      expect(find.byKey(const Key('director-$sachaId')), findsOneWidget);
      expect(find.byKey(const Key('director-$dominiqueId')), findsOneWidget);

      await tester.tap(find.byKey(const Key('removeDirector-$dominiqueId')));
      await tester.pumpAndSettle();
      expect(find.text('Retirer ce directeur ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmButton')));
      await tester.pumpAndSettle();

      expect(find.text('Directeur retiré.'), findsOneWidget);
      expect(find.byKey(const Key('director-$dominiqueId')), findsNothing);
      expect(find.byKey(const Key('director-$sachaId')), findsOneWidget);
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
    'un numéro sans compte propose d\'en créer un, jusqu\'à ce qu\'on en '
    'change ; celui du directeur ou un numéro mal formé est refusé',
    (tester) async {
      await launchAs(tester, demo);
      await openStayAsAdmin(tester, summer);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();

      await nameByPhone(tester, '06 99 99 99 99');
      expect(find.byKey(const Key('newAccountHint')), findsOneWidget);
      expect(find.text('Créer le compte et nommer'), findsOneWidget);

      await nameByPhone(tester, '06 22 22 22 22');
      expect(find.byKey(const Key('newAccountHint')), findsNothing);
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
    'l\'app s\'ouvre sur le séjour du directeur, qui y nomme un adjoint par '
    'son numéro, sans voir les comptes',
    (tester) async {
      await launchAs(tester, dominique);

      // Son seul séjour s'ouvre de lui-même.
      expect(find.byKey(const Key('staysSpace')), findsNothing);
      expect(find.byKey(const Key('adminSpace')), findsNothing);
      expect(inSwitcher('Du 10 au 24 juillet 2027'), findsOneWidget);
      expect(inSwitcher('Directeur'), findsOneWidget);

      await openTeam(tester);

      expect(find.byKey(const Key('addDirectorButton')), findsNothing);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffSearchField')), findsNothing);

      await nameByPhone(tester, '06 33 33 33 33');

      expect(find.text('Adjoint ajouté.'), findsOneWidget);
      expect(find.byKey(const Key('deputy-$sachaId')), findsOneWidget);
    },
  );

  testWidgets(
    'le directeur crée le compte d\'un adjoint qui n\'en a pas encore',
    (tester) async {
      await launchAs(tester, dominique);
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();

      await nameByPhone(tester, '07 11 22 33 44');
      expect(find.byKey(const Key('newAccountHint')), findsOneWidget);

      // Les deux noms sont obligatoires, et l'erreur part dès qu'on corrige.
      await tester.enterText(
        find.byKey(const Key('staffFirstNameField')),
        'Lou',
      );
      await tester.tap(find.byKey(const Key('nameStaffButton')));
      await tester.pumpAndSettle();
      expect(find.text('Le nom est obligatoire.'), findsOneWidget);
      expect(find.text('Le prénom est obligatoire.'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('staffLastNameField')),
        'Petit',
      );
      await tester.pump();
      expect(find.text('Le nom est obligatoire.'), findsNothing);
      await tester.tap(find.byKey(const Key('nameStaffButton')));
      await tester.pumpAndSettle();

      expect(find.text('Compte créé, adjoint ajouté.'), findsOneWidget);
      expect(find.text('Lou Petit'), findsOneWidget);
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

    expect(inSwitcher('Adjoint'), findsOneWidget);
    await openTeam(tester);

    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.byKey(const Key('addDirectorButton')), findsNothing);
    expect(find.byKey(const Key('addDeputyButton')), findsNothing);
    expect(find.byKey(const Key('removeDeputy-$sachaId')), findsNothing);
    // Il affecte en revanche les animateurs.
    expect(find.byKey(const Key('addAnimatorButton')), findsOneWidget);
  });

  testWidgets('un adjoint ajoute un animateur par son numéro, puis le retire', (
    tester,
  ) async {
    await launchAs(
      tester,
      sacha,
      staff: {
        summer: {dominiqueId: StaffRole.director, sachaId: StaffRole.deputy},
      },
    );
    await openTeam(tester);

    await tester.tap(find.byKey(const Key('addAnimatorButton')));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un animateur'), findsOneWidget);
    await nameByPhone(tester, '06 12 34 56 78');

    expect(find.text('Animateur ajouté.'), findsOneWidget);
    expect(find.byKey(Key('animator-${demo.id}')), findsOneWidget);

    await tester.tap(find.byKey(Key('removeAnimator-${demo.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Retirer cet animateur ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('Animateur retiré.'), findsOneWidget);
    expect(find.byKey(const Key('noAnimators')), findsOneWidget);
  });

  testWidgets(
    'le directeur fait passer un adjoint animateur, après confirmation',
    (tester) async {
      await launchAs(
        tester,
        dominique,
        staff: {
          summer: {dominiqueId: StaffRole.director, sachaId: StaffRole.deputy},
        },
      );
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('addAnimatorButton')));
      await tester.pumpAndSettle();

      // Annuler laisse tout en l'état.
      await nameByPhone(tester, '06 33 33 33 33');
      expect(find.text('Passer animateur ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffPhoneField')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nameStaffButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDemoteButton')));
      await tester.pumpAndSettle();

      expect(find.text('Adjoint passé animateur.'), findsOneWidget);
      expect(find.byKey(const Key('animator-$sachaId')), findsOneWidget);
      expect(find.byKey(const Key('deputy-$sachaId')), findsNothing);
    },
  );

  testWidgets(
    'un adjoint ne peut pas faire passer un directeur animateur : le numéro '
    'est refusé sans confirmation',
    (tester) async {
      await launchAs(
        tester,
        sacha,
        staff: {
          summer: {dominiqueId: StaffRole.director, sachaId: StaffRole.deputy},
        },
      );
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('addAnimatorButton')));
      await tester.pumpAndSettle();

      await nameByPhone(tester, '06 22 22 22 22');

      expect(find.text('Passer animateur ?'), findsNothing);
      expect(
        find.text('Cette personne dirige déjà le séjour.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'l\'admin qui se nomme adjoint retrouve le séjour parmi les siens',
    (tester) async {
      await launchAs(tester, demo);
      expect(find.byKey(const Key('myStay-$summer')), findsNothing);

      await openStayAsAdmin(tester, summer);
      await tester.tap(find.byKey(const Key('addDeputyButton')));
      await tester.pumpAndSettle();
      await nameByPhone(tester, '06 12 34 56 78');

      // Le séjour est désormais le sien : il y est adjoint.
      expect(inSwitcher('Adjoint'), findsOneWidget);
    },
  );
}
