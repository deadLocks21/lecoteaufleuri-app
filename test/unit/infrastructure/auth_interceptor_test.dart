import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/infrastructure/http/auth.interceptor.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late InMemorySessionRepository sessions;
  late int unauthorizedSignals;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({}));
    sessions = InMemorySessionRepository(
      sessionExpiringAt(DateTime.utc(2026, 1, 31)),
    );
    unauthorizedSignals = 0;
    dio = dioWith(adapter)
      ..interceptors.add(
        AuthInterceptor(
          sessions: sessions,
          onUnauthorized: () => unauthorizedSignals++,
        ),
      );
  });

  test('pose le Bearer sur une route protégée', () async {
    await dio.get<dynamic>('/api/me');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer jwt-token',
    );
  });

  test('aucun Bearer sur les routes de connexion', () async {
    await dio.post<dynamic>('/api/auth/request-otp');

    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('aucun Bearer sans session', () async {
    await sessions.clear();

    await dio.get<dynamic>('/api/me');

    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('signale un jeton refusé, sans avaler l\'erreur', () async {
    adapter.respond = (_) => FakeHttpAdapter.json({
      'error': 'Token invalide ou manquant.',
      'code': 'invalid_token',
    }, status: 401);

    await expectLater(
      dio.get<dynamic>('/api/me'),
      throwsA(isA<DioException>()),
    );
    expect(unauthorizedSignals, 1);
  });

  test('un mauvais code OTP n\'est pas une session morte', () async {
    adapter.respond = (_) =>
        FakeHttpAdapter.json({'code': 'invalid_otp'}, status: 401);

    await expectLater(
      dio.post<dynamic>('/api/auth/verify-otp'),
      throwsA(isA<DioException>()),
    );
    expect(unauthorizedSignals, 0);
  });
}
