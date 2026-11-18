import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/refresh_session.usecase.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final session = sessionExpiringAt(DateTime.utc(2026, 1, 31));

  test('met à jour le compte de la session enregistrée', () async {
    final sessions = InMemorySessionRepository(session);
    final auth = FakeAuthRepository(camille.copyWith(isAdmin: true));

    final refreshed = await RefreshSessionUseCase(auth, sessions).execute();

    expect(refreshed?.user.isAdmin, isTrue);
    expect((await sessions.read())?.user.isAdmin, isTrue);
    expect((await sessions.read())?.token, session.token);
  });

  test('ne ressuscite pas une session fermée', () async {
    final sessions = InMemorySessionRepository();

    expect(
      await RefreshSessionUseCase(
        FakeAuthRepository(camille),
        sessions,
      ).execute(),
      isNull,
    );
    expect(await sessions.read(), isNull);
  });
}
