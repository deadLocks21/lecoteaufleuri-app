import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/verify_otp.usecase.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';

void main() {
  late InMemorySessionRepository sessions;
  late VerifyOtpUseCase useCase;

  setUp(() {
    sessions = InMemorySessionRepository();
    useCase = VerifyOtpUseCase(
      InMemoryAuthRepository(now: () => DateTime.utc(2026, 1, 1, 12)),
      sessions,
    );
  });

  test(
    'ouvre et enregistre la session, sans livrer le jeton à l\'UI',
    () async {
      final session = await useCase.execute(
        phoneNumber: '+33612345678',
        rawCode: InMemoryAuthRepository.demoCode,
      );

      expect(session.user.firstName, 'Camille');
      expect(session.expiresAt, DateTime.utc(2026, 1, 31, 12));
      expect((await sessions.read())?.token, 'in-memory-token');
    },
  );

  test('un mauvais code n\'enregistre rien', () async {
    await expectLater(
      useCase.execute(phoneNumber: '+33612345678', rawCode: '111111'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.invalidOtp,
        ),
      ),
    );
    expect(await sessions.read(), isNull);
  });

  test('un code incomplet est refusé avant tout appel', () {
    expect(
      useCase.execute(phoneNumber: '+33612345678', rawCode: '000'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.invalidOtp,
        ),
      ),
    );
  });
}
