import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/session/in_memory.session.repository.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fixtures.dart';

/// Le compte de démo, en comptant les SMS demandés.
class CountingAuthRepository implements AuthRepository {
  final _inner = InMemoryAuthRepository();
  int otpRequests = 0;

  @override
  Future<DateTime> requestOtp(PhoneNumber phone) {
    otpRequests++;
    return _inner.requestOtp(phone);
  }

  @override
  Future<Session> verifyOtp(PhoneNumber phone, OtpCode code) =>
      _inner.verifyOtp(phone, code);
}

void main() {
  late InMemorySessionRepository sessions;
  late CountingAuthRepository auth;
  late ProviderContainer container;

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);
  SessionState state() => container.read(sessionControllerProvider);

  Future<ProviderContainer> start({List<Override> overrides = const []}) async {
    container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        authRepositoryProvider.overrideWithValue(auth),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionControllerProvider);
    await pumpEventQueue();
    return container;
  }

  Future<void> logIn() async {
    await controller().requestOtp('06 12 34 56 78');
    await controller().verifyOtp(InMemoryAuthRepository.demoCode);
  }

  setUp(() {
    sessions = InMemorySessionRepository();
    auth = CountingAuthRepository();
  });

  test('reprend au démarrage la session enregistrée', () async {
    sessions = InMemorySessionRepository(
      sessionExpiringAt(DateTime.now().add(const Duration(days: 1))),
    );

    await start();

    expect(state(), isA<Authenticated>());
  });

  test('sans session, attend un numéro', () async {
    await start();

    expect(state(), isA<Anonymous>());
  });

  test('numéro, puis code : la session est ouverte et enregistrée', () async {
    await start();

    expect(await controller().requestOtp('06 12 34 56 78'), isNull);
    expect(
      state(),
      isA<OtpRequested>().having(
        (s) => s.phoneNumber,
        'phoneNumber',
        '+33612345678',
      ),
    );

    expect(
      await controller().verifyOtp(InMemoryAuthRepository.demoCode),
      isNull,
    );
    expect(
      state(),
      isA<Authenticated>().having(
        (s) => s.session.user.firstName,
        'firstName',
        'Camille',
      ),
    );
    expect(await sessions.read(), isNotNull);
  });

  test('un échec rend son code et laisse l\'état en place', () async {
    await start();

    expect(
      await controller().requestOtp('07 99 99 99 99'),
      AuthErrorCode.accountNotFound,
    );
    expect(state(), isA<Anonymous>());

    await controller().requestOtp('06 12 34 56 78');
    expect(await controller().verifyOtp('111111'), AuthErrorCode.invalidOtp);
    expect(state(), isA<OtpRequested>());
  });

  test('la déconnexion oublie la session', () async {
    await start();
    await logIn();

    await controller().logout();

    expect(state(), isA<Anonymous>());
    expect(await sessions.read(), isNull);
  });

  test(
    'un jeton refusé renvoie un seul SMS, même sur des 401 simultanés',
    () async {
      await start();
      await logIn();
      auth.otpRequests = 0;

      await Future.wait([controller().expire(), controller().expire()]);

      expect(auth.otpRequests, 1);
      expect(await sessions.read(), isNull);
      expect(
        state(),
        isA<OtpRequested>()
            .having((s) => s.reason, 'reason', OtpReason.sessionExpired)
            .having((s) => s.phoneNumber, 'phoneNumber', '+33612345678'),
      );
    },
  );

  test('un 401 invalid_token reçu par Dio relance la connexion', () async {
    await start(
      overrides: [apiBaseUrlProvider.overrideWithValue('http://api.test')],
    );
    await logIn();
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'error': 'Token invalide ou manquant.',
        'code': 'invalid_token',
      }, status: 401),
    );
    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await expectLater(
      dio.get<dynamic>('/api/me'),
      throwsA(isA<DioException>()),
    );
    await pumpEventQueue();

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer in-memory-token',
    );
    expect(
      state(),
      isA<OtpRequested>().having(
        (s) => s.reason,
        'reason',
        OtpReason.sessionExpired,
      ),
    );
  });
}
