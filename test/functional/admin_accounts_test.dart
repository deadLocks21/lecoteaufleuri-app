import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fixtures.dart';

/// Administration des comptes de bout en bout, en mode mémoire : le compte de
/// démo est admin, et deux autres comptes existent (Dominique Durand, Sacha
/// Bernard).
void main() {
  const dominiqueId = '0a5c0000-0000-4000-8000-000000000101';
  final demo = InMemoryAuthRepository.demoUser;

  Future<FakeAuthRepository> launchAs(WidgetTester tester, User user) async {
    final auth = FakeAuthRepository(user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(
            InMemorySessionRepository(
              Session(
                token: 'in-memory-token',
                expiresAt: DateTime.now().add(const Duration(days: 1)),
                user: user,
              ),
            ),
          ),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Future<void> openAccounts(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('accountsSpace')));
    await tester.pumpAndSettle();
  }

  Future<void> fillAccount(
    WidgetTester tester, {
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    await tester.enterText(find.byKey(const Key('accountPhoneField')), phone);
    await tester.enterText(
      find.byKey(const Key('accountFirstNameField')),
      firstName,
    );
    await tester.enterText(
      find.byKey(const Key('accountLastNameField')),
      lastName,
    );
    await tester.tap(find.byKey(const Key('saveAccountButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('un compte sans statut d\'admin ne voit pas l\'administration', (
    tester,
  ) async {
    await launchAs(tester, camille);

    expect(find.text('Bonjour Camille !'), findsOneWidget);
    expect(find.byKey(const Key('accountsSpace')), findsNothing);
    expect(find.byKey(const Key('emptyHome')), findsOneWidget);
  });

  testWidgets('l\'admin voit les comptes et en crée un', (tester) async {
    await launchAs(tester, demo);
    await openAccounts(tester);

    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.text('06 22 22 22 22'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newAccountButton')));
    await tester.pumpAndSettle();
    await fillAccount(
      tester,
      phone: '07 11 22 33 44',
      firstName: 'Lou',
      lastName: 'Petit',
    );

    expect(find.text('Compte créé.'), findsOneWidget);
    expect(find.text('Lou Petit'), findsOneWidget);
  });

  testWidgets('un numéro déjà pris est refusé sur le champ', (tester) async {
    await launchAs(tester, demo);
    await openAccounts(tester);
    await tester.tap(find.byKey(const Key('newAccountButton')));
    await tester.pumpAndSettle();

    await fillAccount(
      tester,
      phone: '06 22 22 22 22',
      firstName: 'Lou',
      lastName: 'Petit',
    );

    expect(
      find.text('Ce numéro est déjà celui d\'un autre compte.'),
      findsOneWidget,
    );
  });

  testWidgets('la recherche filtre par nom ou par numéro', (tester) async {
    await launchAs(tester, demo);
    await openAccounts(tester);

    await tester.enterText(
      find.byKey(const Key('accountSearchField')),
      'durand',
    );
    await tester.pump();
    expect(find.text('Dominique Durand'), findsOneWidget);
    expect(find.text('Sacha Bernard'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('accountSearchField')),
      '06 33',
    );
    await tester.pump();
    expect(find.text('Sacha Bernard'), findsOneWidget);
    expect(find.text('Dominique Durand'), findsNothing);
  });

  testWidgets('une suppression se confirme', (tester) async {
    await launchAs(tester, demo);
    await openAccounts(tester);
    await tester.tap(find.byKey(const Key('account-$dominiqueId')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deleteAccountButton')));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce compte ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('Compte supprimé.'), findsOneWidget);
    expect(find.text('Dominique Durand'), findsNothing);
  });

  testWidgets(
    'le dernier admin garde son statut, et ne peut pas supprimer son compte',
    (tester) async {
      await launchAs(tester, demo);
      await openAccounts(tester);
      await tester.tap(find.byKey(Key('account-${demo.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deleteAccountButton')), findsNothing);

      await tester.tap(find.byKey(const Key('adminSwitch')));
      await tester.pumpAndSettle();

      expect(
        find.text('C\'est le dernier admin : nommez-en un autre d\'abord.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('adminSwitch')))
            .value,
        isTrue,
      );
    },
  );

  testWidgets('se retirer le statut d\'admin referme l\'administration', (
    tester,
  ) async {
    final auth = await launchAs(tester, demo);
    await openAccounts(tester);

    // Un autre admin d'abord, pour ne pas être le dernier.
    await tester.tap(find.byKey(const Key('account-$dominiqueId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminSwitch')));
    await tester.pumpAndSettle();
    // `pageBack()` cherche l'infobulle anglaise « Back » ; l'app est en français.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('account-${demo.id}')));
    await tester.pumpAndSettle();
    auth.current = demo.copyWith(isAdmin: false);
    await tester.tap(find.byKey(const Key('adminSwitch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accountsSpace')), findsNothing);
    expect(find.byKey(const Key('emptyHome')), findsOneWidget);
  });
}
