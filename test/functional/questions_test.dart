import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/questions.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/questions/in_memory.questions.repository.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.last_stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// Les questions d'un séjour de bout en bout, en mémoire : l'été 2027 de
/// démo, dirigé par Dominique Durand, avec Sacha Bernard pour animateur.
void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';
  final dominique = InMemoryAccountRepository.demoAccounts[1];
  final sacha = InMemoryAccountRepository.demoAccounts[2];
  final staff = {
    summer: {dominique.id: StaffRole.director, sacha.id: StaffRole.animator},
  };

  late User viewer;
  late InMemoryQuestionsRepository questions;

  /// Lance l'app pour [user], les questions déjà posées par [seed] (au nom
  /// de qui il faut).
  Future<void> launchAs(
    WidgetTester tester,
    User user, {
    Future<void> Function()? seed,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    viewer = user;
    final stays = InMemoryStayRepository(
      staff: staff,
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
    );
    questions = InMemoryQuestionsRepository(
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
      roleOf: stays.roleIn,
      authorOf: (id) => switch (stays.accountById(id)) {
        final a? => QuestionAuthor(
          id: a.id,
          firstName: a.firstName,
          lastName: a.lastName,
        ),
        null => null,
      },
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
          questionsRepositoryProvider.overrideWithValue(questions),
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
    'un animateur pose sa question à la direction, sans pouvoir la publier',
    (tester) async {
      await launchAs(tester, sacha);

      await tapKey(tester, 'questionsModule');
      expect(find.byKey(const Key('noQuestions')), findsOneWidget);
      expect(find.byKey(const Key('deletedQuestions')), findsNothing);

      await tapKey(tester, 'askQuestion');
      expect(find.byKey(const Key('questionVisibility')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('questionTitle')),
        'Peut-on veiller ?',
      );
      await tester.pump();
      await tapKey(tester, 'submitQuestion');

      // Le fil s'ouvre : la question est privée, il peut y répondre.
      expect(find.text('Peut-on veiller ?'), findsOneWidget);
      expect(find.byKey(const Key('privateBadge')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('replyField')),
        'Le soir du feu de camp.',
      );
      await tester.pump();
      await tapKey(tester, 'sendReply');
      expect(find.text('Le soir du feu de camp.'), findsOneWidget);

      await tapKey(tester, 'questionActions');
      expect(find.byKey(const Key('changeVisibility')), findsNothing);
      expect(find.byKey(const Key('toggleResolved')), findsNothing);
      expect(find.byKey(const Key('editQuestion')), findsOneWidget);
    },
  );

  testWidgets(
    'la direction publie une question d\'animateur en taisant son nom, puis '
    'la résout',
    (tester) async {
      late Question asked;
      await launchAs(
        tester,
        dominique,
        seed: () async {
          viewer = sacha;
          asked = await questions.ask(summer, title: 'Peut-on veiller ?');
        },
      );

      await tapKey(tester, 'questionsModule');
      expect(find.byKey(const Key('deletedQuestions')), findsOneWidget);
      await tapKey(tester, 'question-${asked.id}');
      expect(find.textContaining('Sacha Bernard'), findsOneWidget);

      await tapKey(tester, 'questionActions');
      await tapKey(tester, 'changeVisibility');
      expect(find.byKey(const Key('anonymousSwitch')), findsOneWidget);
      await tapKey(tester, 'submitVisibility');
      expect(find.byKey(const Key('publicBadge')), findsOneWidget);
      expect(find.byKey(const Key('anonymousBadge')), findsOneWidget);
      // La direction voit toujours le nom.
      expect(find.textContaining('Sacha Bernard'), findsOneWidget);

      await tapKey(tester, 'questionActions');
      await tapKey(tester, 'toggleResolved');
      expect(find.byKey(const Key('resolvedBadge')), findsOneWidget);
    },
  );
}
