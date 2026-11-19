import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fixtures.dart';

/// Administration des séjours de bout en bout, en mode mémoire : le compte de
/// démo est admin, et deux séjours existent (« Été 2027 — Pyrénées », ACM, et
/// « Week-end des animateurs », hors ACM).
void main() {
  final demo = InMemoryAuthRepository.demoUser;
  // L'année prochaine : toujours dans les bornes du calendrier.
  final year = DateTime.now().year + 1;

  Future<void> launchAs(
    WidgetTester tester,
    User user, {
    StayRepository? stays,
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
          if (stays != null) stayRepositoryProvider.overrideWithValue(stays),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNewStay(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('staysSpace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newStayButton')));
    await tester.pumpAndSettle();
  }

  /// Choisit les dates par la saisie au clavier du calendrier (JJ/MM/AAAA).
  Future<void> pickDates(WidgetTester tester, String start, String end) async {
    await tester.tap(find.byKey(const Key('stayDatesField')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Passer à la saisie'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Premier jour'),
      start,
    );
    await tester.enterText(find.widgetWithText(TextField, 'Dernier jour'), end);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('saveStayButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('un compte sans statut d\'admin ne voit pas les séjours', (
    tester,
  ) async {
    await launchAs(tester, camille);

    expect(find.byKey(const Key('staysSpace')), findsNothing);
  });

  testWidgets('l\'admin voit les séjours, le dernier commencé en tête', (
    tester,
  ) async {
    await launchAs(tester, demo);
    await tester.tap(find.byKey(const Key('staysSpace')));
    await tester.pumpAndSettle();

    expect(find.text('Du 10 au 24 juillet 2027 · ACM'), findsOneWidget);
    expect(find.text('Du 13 au 14 mars 2027 · Hors ACM'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Été 2027 — Pyrénées')).dy,
      lessThan(tester.getTopLeft(find.text('Week-end des animateurs')).dy),
    );
  });

  testWidgets('l\'admin crée un séjour', (tester) async {
    await launchAs(tester, demo);
    await openNewStay(tester);

    await tester.enterText(
      find.byKey(const Key('stayNameField')),
      'Camp d\'été $year',
    );
    await tester.tap(find.text('Hors ACM'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chaque participant est inscrit en son nom.'),
      findsOneWidget,
    );

    await pickDates(tester, '03/08/$year', '07/08/$year');
    expect(find.text('Du 3 au 7 août $year'), findsOneWidget);

    await save(tester);

    expect(find.text('Séjour créé.'), findsOneWidget);
    expect(find.text('Camp d\'été $year'), findsOneWidget);
    expect(find.text('Du 3 au 7 août $year · Hors ACM'), findsOneWidget);
  });

  testWidgets(
    'chaque champ manquant est signalé à son tour, et l\'erreur part dès '
    'qu\'on le corrige',
    (tester) async {
      await launchAs(tester, demo);
      await openNewStay(tester);

      await save(tester);
      expect(
        find.text('Le nom du séjour est obligatoire (255 caractères au plus).'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('stayNameField')), 'Été');
      await tester.pump();
      expect(
        find.text('Le nom du séjour est obligatoire (255 caractères au plus).'),
        findsNothing,
      );

      await save(tester);
      expect(find.text('Choisissez la nature du séjour.'), findsOneWidget);

      await tester.tap(find.text('ACM'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez la nature du séjour.'), findsNothing);

      await save(tester);
      expect(
        find.text('Choisissez le premier et le dernier jour du séjour.'),
        findsOneWidget,
      );
      expect(find.text('Séjour créé.'), findsNothing);
    },
  );

  testWidgets('un refus du serveur s\'affiche à la place de la liste', (
    tester,
  ) async {
    await launchAs(
      tester,
      demo,
      stays: _FailingStayRepository(StayErrorCode.forbidden),
    );
    await tester.tap(find.byKey(const Key('staysSpace')));
    await tester.pumpAndSettle();

    expect(
      find.text('Vous n\'avez pas (ou plus) accès à la gestion des séjours.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('newStayButton')), findsNothing);
  });
}

class _FailingStayRepository implements StayRepository {
  final StayErrorCode code;

  _FailingStayRepository(this.code);

  @override
  Future<List<Stay>> list() async => throw StayException(code);

  @override
  Future<Stay> create(StayDraft draft) async => throw StayException(code);

  @override
  Future<StayDetail> get(String stayId) async => throw StayException(code);

  @override
  Future<StayDetail> nameDirector(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  }) async => throw StayException(code);

  @override
  Future<StayDetail> removeDirector(String stayId, String accountId) async =>
      throw StayException(code);

  @override
  Future<StayDetail> addDeputy(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  }) async => throw StayException(code);

  @override
  Future<StayDetail> removeDeputy(String stayId, String accountId) async =>
      throw StayException(code);

  @override
  Future<StayDetail> addAnimator(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
    bool demote = false,
  }) async => throw StayException(code);

  @override
  Future<StayDetail> removeAnimator(String stayId, String accountId) async =>
      throw StayException(code);

  @override
  Future<List<MyStay>> mine() async => throw StayException(code);
}
