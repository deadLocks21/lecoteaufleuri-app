import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/restore_session.usecase.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';

import '../../../helpers/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15);

  test('reprend une session encore valable', () async {
    final sessions = InMemorySessionRepository(
      sessionExpiringAt(DateTime.utc(2026, 1, 31)),
    );

    final restored = await RestoreSessionUseCase(
      sessions,
      now: () => now,
    ).execute();

    expect(restored?.user.firstName, 'Camille');
  });

  test('efface une session expirée', () async {
    final sessions = InMemorySessionRepository(
      sessionExpiringAt(DateTime.utc(2026, 1, 1)),
    );

    final restored = await RestoreSessionUseCase(
      sessions,
      now: () => now,
    ).execute();

    expect(restored, isNull);
    expect(await sessions.read(), isNull);
  });

  test('rien à reprendre au premier lancement', () async {
    expect(
      await RestoreSessionUseCase(
        InMemorySessionRepository(),
        now: () => now,
      ).execute(),
      isNull,
    );
  });
}
