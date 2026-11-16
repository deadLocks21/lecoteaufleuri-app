import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';

void main() {
  group('OtpCode', () {
    test('accepte exactement 6 chiffres', () {
      expect(OtpCode.parse(' 004217 ').value, '004217');
    });

    test('refuse un code incomplet ou non numérique', () {
      for (final raw in ['', '12345', '1234567', '12a456']) {
        expect(
          () => OtpCode.parse(raw),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidOtp,
            ),
          ),
          reason: raw,
        );
      }
    });
  });
}
