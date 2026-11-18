import 'dart:async';

import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/infrastructure/http/auth.interceptor.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio.provider.g.dart';

/// Client HTTP partagé par tous les `dio.*.repository.dart`.
///
/// Son [AuthInterceptor] pose le Bearer et, sur `401 invalid_token`, demande au
/// [SessionController] de relancer la connexion ; sur `403 forbidden`, de
/// relire les droits du compte. Le contrôleur est lu
/// paresseusement (`ref.read` dans le callback) : le résoudre à la construction
/// bouclerait (`dio → sessionController → authService → authRepository → dio`).
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      sessions: ref.watch(sessionRepositoryProvider),
      onUnauthorized: () =>
          unawaited(ref.read(sessionControllerProvider.notifier).expire()),
      onForbidden: () =>
          unawaited(ref.read(sessionControllerProvider.notifier).refresh()),
    ),
  );
  return dio;
}
