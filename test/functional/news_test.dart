import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/photo_picker.service.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/news/demo_photos.dart';
import 'package:lecoteaufleuri/infrastructure/news/in_memory.news.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/photo_picker.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';

import '../helpers/fake_auth_repository.dart';

/// Deux photos choisies sur l'appareil, à chaque fois.
class _TwoPhotos implements PhotoPicker {
  @override
  Future<List<PickedPhoto>> pick() async => [
    PickedPhoto(name: 'lac.png', bytes: DemoPhotos.scene(0)),
    PickedPhoto(name: 'foret.png', bytes: DemoPhotos.scene(1)),
  ];
}

/// Les nouvelles d'un séjour de bout en bout, en mémoire : l'été 2027 de
/// démo, dirigé par Dominique Durand, avec Sacha Bernard pour animateur.
void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';
  final dominique = InMemoryAccountRepository.demoAccounts[1];
  final sacha = InMemoryAccountRepository.demoAccounts[2];
  final staff = {
    summer: {dominique.id: StaffRole.director, sacha.id: StaffRole.animator},
  };

  late User viewer;
  late InMemoryNewsRepository news;

  Future<void> launchAs(WidgetTester tester, User user) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    viewer = user;
    final stays = InMemoryStayRepository(
      staff: staff,
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
    );
    news = InMemoryNewsRepository(
      viewer: () => (id: viewer.id, isAdmin: viewer.isAdmin),
      roleOf: stays.roleIn,
      stayOf: stays.stayById,
      authorOf: (id) => switch (stays.accountById(id)) {
        final account? => PhotoAuthor(
          id: account.id,
          firstName: account.firstName,
          lastName: account.lastName,
        ),
        null => null,
      },
    );
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
          stayRepositoryProvider.overrideWithValue(stays),
          newsRepositoryProvider.overrideWithValue(news),
          photoPickerProvider.overrideWithValue(_TwoPhotos()),
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

  testWidgets(
    'un animateur dépose ses photos et les trie en série, sans voir les jours',
    (tester) async {
      await launchAs(tester, sacha);

      await tapKey(tester, 'myStay-$summer');
      expect(find.byKey(const Key('stayDaysSpace')), findsNothing);
      await tapKey(tester, 'myPhotosSpace');
      expect(find.byKey(const Key('noPhotos')), findsOneWidget);

      await tapKey(tester, 'addPhotosButton');
      expect(find.text('2 photos ajoutées, à trier.'), findsOneWidget);
      expect(find.text('À trier · 2'), findsOneWidget);

      await tapKey(tester, 'sortPendingButton');
      expect(find.text('1 / 2'), findsOneWidget);
      await tapKey(tester, 'keepButton');
      expect(find.text('2 / 2'), findsOneWidget);
      await tapKey(tester, 'discardButton');

      expect(find.text('Tri terminé.'), findsOneWidget);
      expect(find.text('Retenues · 1'), findsOneWidget);
      expect(find.text('Écartées · 1'), findsOneWidget);
      expect(find.byKey(const Key('sortPendingButton')), findsNothing);
    },
  );

  testWidgets(
    'le directeur compose un jour avec les photos de l\'équipe et le publie',
    (tester) async {
      await launchAs(tester, dominique);
      // Sacha a déposé deux photos.
      viewer = sacha;
      for (final photo in await _TwoPhotos().pick()) {
        await news.upload(summer, photo);
      }
      viewer = dominique;

      await tapKey(tester, 'myStay-$summer');
      await tapKey(tester, 'stayDaysSpace');
      expect(find.byKey(const Key('noDays')), findsOneWidget);

      // Le premier jour libre du séjour, à venir : le 10 juillet.
      await tapKey(tester, 'newDayButton');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();
      expect(find.text('Samedi 10 juillet'), findsOneWidget);
      expect(find.byKey(const Key('status-draft')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('summaryField')),
        'Tout le monde est bien arrivé !',
      );
      await tester.pump();
      await tapKey(tester, 'saveSummaryButton');
      expect(find.text('Résumé enregistré.'), findsOneWidget);

      // La pioche : les photos de Sacha, choisies dans l'ordre voulu.
      await tapKey(tester, 'pickDayPhotosButton');
      final photos = await news.photos(summer);
      expect(photos, hasLength(2));
      await tapKey(tester, 'pick-${photos[1].id}');
      await tapKey(tester, 'pick-${photos[0].id}');
      await tapKey(tester, 'confirmPickButton');
      expect(find.byKey(Key('dayPhoto-${photos[1].id}')), findsOneWidget);
      expect(find.byKey(Key('dayPhoto-${photos[0].id}')), findsOneWidget);

      await tapKey(tester, 'publishNowButton');
      expect(find.text('Jour publié.'), findsOneWidget);
      expect(find.byKey(const Key('status-published')), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('status-published')), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tapKey(tester, 'stayNewsSpace');
      expect(find.byKey(const Key('familiesView')), findsOneWidget);
      expect(find.text('Samedi 10 juillet'), findsOneWidget);
      expect(find.text('Tout le monde est bien arrivé !'), findsOneWidget);
      expect(find.byKey(Key('newsPhoto-${photos[1].id}')), findsOneWidget);
      expect(find.byKey(Key('newsPhoto-${photos[0].id}')), findsOneWidget);
    },
  );

  testWidgets('un jour vide ne se publie pas', (tester) async {
    await launchAs(tester, dominique);
    await tapKey(tester, 'myStay-$summer');
    await tapKey(tester, 'stayDaysSpace');
    await tapKey(tester, 'newDayButton');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final publish = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Publier maintenant'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(publish.onPressed, isNull);
    expect(
      find.text('Ajoutez un résumé ou des photos pour publier.'),
      findsOneWidget,
    );
  });

  testWidgets('l\'animateur lit les nouvelles publiées seulement', (
    tester,
  ) async {
    await launchAs(tester, sacha);
    viewer = sacha;
    final photo = await news.upload(summer, (await _TwoPhotos().pick())[0]);
    viewer = dominique;
    final published = await news.createDay(summer, DateTime.utc(2027, 7, 10));
    await news.updateDay(
      summer,
      published.id,
      date: DateTime.utc(2027, 7, 10),
      summary: 'Arrivée',
    );
    await news.setDayPhotos(summer, published.id, [photo.id]);
    await news.publishDay(summer, published.id);
    final draft = await news.createDay(summer, DateTime.utc(2027, 7, 11));
    await news.updateDay(
      summer,
      draft.id,
      date: DateTime.utc(2027, 7, 11),
      summary: 'Brouillon',
    );
    viewer = sacha;

    await tapKey(tester, 'myStay-$summer');
    await tapKey(tester, 'newsFeedSpace');

    expect(find.byKey(Key('news-${published.id}')), findsOneWidget);
    expect(find.text('Arrivée'), findsOneWidget);
    expect(find.text('Brouillon'), findsNothing);
    expect(find.byKey(const Key('familiesView')), findsNothing);

    await tapKey(tester, 'newsPhoto-${photo.id}');
    expect(find.byKey(const Key('sortingButtons')), findsNothing);
    expect(find.byKey(const Key('deletePhotoButton')), findsNothing);
  });
}
