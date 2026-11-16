import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/request_otp.usecase.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);
  final useCase = RequestOtpUseCase(InMemoryAuthRepository(now: () => now));

  test('envoie le code au numéro normalisé', () async {
    final otp = await useCase.execute('06 12 34 56 78');

    expect(otp.phoneNumber, '+33612345678');
    expect(otp.expiresAt, DateTime.utc(2026, 1, 1, 12, 5));
  });

  test('refuse un numéro mal formé sans appeler le serveur', () {
    expect(
      useCase.execute('12'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.invalidPhone,
        ),
      ),
    );
  });

  test('remonte un compte inconnu', () {
    expect(
      useCase.execute('07 99 99 99 99'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          AuthErrorCode.accountNotFound,
        ),
      ),
    );
  });
}
