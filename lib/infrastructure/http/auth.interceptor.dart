import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';

/// Ajoute `Authorization: Bearer <jwt>` à chaque requête protégée, et signale
/// tout `401 invalid_token` via [onUnauthorized] pour relancer la connexion.
///
/// Les routes `/api/auth/*` sont exclues dans les deux sens : elles sont
/// publiques, et `verify-otp` répond aussi 401 (`invalid_otp`) à un mauvais
/// code — une erreur de saisie, pas une session morte.
///
/// La session est relue à chaque requête : un seul intercepteur traverse
/// connexions et déconnexions. L'erreur est toujours transmise telle quelle à
/// l'appelant ; la dé-duplication des 401 simultanés revient au callback.
class AuthInterceptor extends Interceptor {
  final SessionRepository _sessions;
  final void Function()? _onUnauthorized;

  AuthInterceptor({
    required SessionRepository sessions,
    void Function()? onUnauthorized,
  }) : _sessions = sessions,
       _onUnauthorized = onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.startsWith(ApiEndpoints.authPrefix)) {
      final session = await _sessions.read();
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.token}';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!err.requestOptions.path.startsWith(ApiEndpoints.authPrefix) &&
        err.response?.statusCode == 401 &&
        readErrorCode(err.response) == 'invalid_token') {
      _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
