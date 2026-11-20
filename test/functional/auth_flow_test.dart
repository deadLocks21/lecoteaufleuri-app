import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.last_stay.repository.dart';
import 'package:lecoteaufleuri/main.dart';
import 'package:lecoteaufleuri/ui/pages/auth/otp_verify.page.dart';

import '../helpers/fixtures.dart';

/// Parcours de connexion de bout en bout, en mode mémoire (compte de démo
/// `06 12 34 56 78`, code `000000`).
void main() {
  Future<InMemorySessionRepository> launch(
    WidgetTester tester, {
    InMemorySessionRepository? sessions,
  }) async {
    final repository = sessions ?? InMemorySessionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastStayRepositoryProvider.overrideWithValue(
            InMemoryLastStayRepository(),
          ),
          sessionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const LeCoteauFleuriApp(),
      ),
    );
    await tester.pump();
    return repository;
  }

  Future<void> submitPhone(WidgetTester tester, String phone) async {
    await tester.enterText(find.byKey(const Key('phoneNumberField')), phone);
    await tester.tap(find.byKey(const Key('requestOtpButton')));
    await tester.pump();
  }

  Future<void> submitCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('otpField')), code);
    await tester.tap(find.byKey(const Key('verifyOtpButton')));
    await tester.pump();
  }

  testWidgets('connexion par SMS puis déconnexion', (tester) async {
    final sessions = await launch(tester);
    expect(find.text('Recevoir le code'), findsOneWidget);

    await submitPhone(tester, '07 99 99 99 99');
    expect(
      find.text('Aucun compte pour ce numéro. Contactez l\'administrateur.'),
      findsOneWidget,
    );

    await submitPhone(tester, '06 12 34 56 78');
    expect(find.byType(OtpVerifyPage), findsOneWidget);
    expect(
      find.text('Saisissez le code à 6 chiffres envoyé au +33612345678.'),
      findsOneWidget,
    );

    await submitCode(tester, '111111');
    expect(find.text('Code incorrect.'), findsOneWidget);

    await submitCode(tester, '000000');
    // Le compte de démo est admin et n'a aucun séjour : l'app s'ouvre sur
    // l'administration, une fois ses séjours lus.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staysSpace')), findsOneWidget);
    expect(await sessions.read(), isNotNull);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();
    expect(find.text('Recevoir le code'), findsOneWidget);
    expect(await sessions.read(), isNull);
  });

  testWidgets(
    'la connexion affiche le logo, en version sombre sur fond sombre',
    (tester) async {
      String logoAsset() =>
          (tester.widget<Image>(find.byKey(const Key('brandLogo'))).image
                  as AssetImage)
              .assetName;

      await launch(tester);
      expect(logoAsset(), 'assets/brand/logo.png');
      expect(find.bySemanticsLabel('Domaine du Coteau Fleuri'), findsOneWidget);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();

      expect(logoAsset(), 'assets/brand/logo_dark.png');
    },
  );

  testWidgets('une session enregistrée ouvre directement l\'app', (
    tester,
  ) async {
    await launch(
      tester,
      sessions: InMemorySessionRepository(
        sessionExpiringAt(DateTime.now().add(const Duration(days: 1))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staysSpace')), findsOneWidget);
  });

  testWidgets('on peut corriger son numéro depuis l\'écran du code', (
    tester,
  ) async {
    await launch(tester);
    await submitPhone(tester, '06 12 34 56 78');

    await tester.tap(find.byKey(const Key('otpBackButton')));
    await tester.pump();

    expect(find.text('Recevoir le code'), findsOneWidget);
  });

  testWidgets('le renvoi du code attend une minute', (tester) async {
    await launch(tester);
    await submitPhone(tester, '06 12 34 56 78');

    expect(find.text('Renvoyer un code dans 60 s'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('resendOtpButton')))
          .onPressed,
      isNull,
    );

    await tester.pump(OtpVerifyPage.resendCooldown);

    expect(find.text('Renvoyer un code'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resendOtpButton')));
    await tester.pump();
    expect(find.text('Renvoyer un code dans 60 s'), findsOneWidget);
  });
}
