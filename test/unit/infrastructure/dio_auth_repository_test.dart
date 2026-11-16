import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/infrastructure/auth/dio.auth.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  final phone = PhoneNumber.parse('0612345678');
  final code = OtpCode.parse('123456');

  Matcher failsWith(AuthErrorCode expected) =>
      throwsA(isA<AuthException>().having((e) => e.code, 'code', expected));

  group('requestOtp', () {
    test('poste le numéro E.164 et lit l\'échéance', () async {
      final adapter = FakeHttpAdapter(
        (_) =>
            FakeHttpAdapter.json({'expires_at': '2026-01-01T12:05:00+00:00'}),
      );

      final expiresAt = await DioAuthRepository(
        dioWith(adapter),
      ).requestOtp(phone);

      expect(expiresAt, DateTime.utc(2026, 1, 1, 12, 5));
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/api/auth/request-otp');
      expect(adapter.requests.single.data, {'phone_number': '+33612345678'});
    });

    test('traduit chaque code d\'erreur de l\'API', () async {
      const expected = {
        'invalid_phone_format': AuthErrorCode.invalidPhone,
        'unknown_phone_number': AuthErrorCode.accountNotFound,
        'rate_limited': AuthErrorCode.rateLimited,
        'sms_failed': AuthErrorCode.smsFailed,
        'invalid_otp': AuthErrorCode.invalidOtp,
        'otp_expired': AuthErrorCode.otpExpired,
        'something_new': AuthErrorCode.unknown,
      };
      for (final MapEntry(key: apiCode, value: code) in expected.entries) {
        final repository = DioAuthRepository(
          dioWith(
            FakeHttpAdapter(
              (_) => FakeHttpAdapter.json({
                'error': 'Message',
                'code': apiCode,
              }, status: 400),
            ),
          ),
        );

        await expectLater(
          repository.requestOtp(phone),
          failsWith(code),
          reason: apiCode,
        );
      }
    });

    test('distingue un serveur muet…', () {
      final repository = DioAuthRepository(
        dioWith(
          FakeHttpAdapter((_) => throw const SocketException('unreachable')),
        ),
      );

      expect(repository.requestOtp(phone), failsWith(AuthErrorCode.network));
    });

    test('…d\'un serveur qui n\'est pas l\'API', () {
      final repository = DioAuthRepository(
        dioWith(FakeHttpAdapter((_) => FakeHttpAdapter.html())),
      );

      expect(
        repository.requestOtp(phone),
        failsWith(AuthErrorCode.badServerUrl),
      );
    });
  });

  group('verifyOtp', () {
    test('poste le code et lit la session', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({
          'token': 'jwt-token',
          'expires_at': '2026-01-31T12:00:00+00:00',
          'user': {
            'id': '0a5c0000-0000-4000-8000-0000000000ff',
            'phone_number': '+33612345678',
            'first_name': 'Camille',
            'last_name': 'Martin',
          },
        }),
      );

      final session = await DioAuthRepository(
        dioWith(adapter),
      ).verifyOtp(phone, code);

      expect(session.token, 'jwt-token');
      expect(session.expiresAt, DateTime.utc(2026, 1, 31, 12));
      expect(session.user.lastName, 'Martin');
      expect(adapter.requests.single.path, '/api/auth/verify-otp');
      expect(adapter.requests.single.data, {
        'phone_number': '+33612345678',
        'code': '123456',
      });
    });

    test('une réponse sans jeton n\'est pas celle de l\'API', () {
      final repository = DioAuthRepository(
        dioWith(FakeHttpAdapter((_) => FakeHttpAdapter.json({'ok': true}))),
      );

      expect(
        repository.verifyOtp(phone, code),
        failsWith(AuthErrorCode.badServerUrl),
      );
    });

    test('un mauvais code reste un mauvais code', () {
      final repository = DioAuthRepository(
        dioWith(
          FakeHttpAdapter(
            (_) => FakeHttpAdapter.json({
              'error': 'Code invalide.',
              'code': 'invalid_otp',
            }, status: 401),
          ),
        ),
      );

      expect(
        repository.verifyOtp(phone, code),
        failsWith(AuthErrorCode.invalidOtp),
      );
    });
  });
}
