import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';

void main() {
  group('PhoneNumber', () {
    test('normalise les saisies usuelles d\'un mobile français en E.164', () {
      for (final raw in [
        '0612345678',
        '06 12 34 56 78',
        '06.12.34.56.78',
        '06-12-34-56-78',
        '+33612345678',
        '+33 6 12 34 56 78',
        '0033612345678',
        '33612345678',
      ]) {
        expect(PhoneNumber.parse(raw).e164, '+33612345678', reason: raw);
      }
      expect(PhoneNumber.parse('07 12 34 56 78').e164, '+33712345678');
    });

    test('refuse ce qui n\'est pas un mobile français', () {
      for (final raw in [
        '',
        '0112345678',
        '061234567',
        '+31612345678',
        'abc',
      ]) {
        expect(
          () => PhoneNumber.parse(raw),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidPhone,
            ),
          ),
          reason: raw,
        );
      }
    });
  });
}
