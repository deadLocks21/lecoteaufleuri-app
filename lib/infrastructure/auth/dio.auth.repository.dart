import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/session/session.codec.dart';

/// [AuthRepository] sur HTTP : `POST /api/auth/request-otp` puis
/// `POST /api/auth/verify-otp` (cf. `API.md` du dépôt api).
///
/// Toute erreur devient une [AuthException], en lisant d'abord le `code`
/// machine de la réponse, puis en distinguant « rien n'a répondu » (réseau) de
/// « quelqu'un d'autre que l'API a répondu » (URL du serveur erronée).
class DioAuthRepository implements AuthRepository {
  final Dio _dio;

  DioAuthRepository(this._dio);

  @override
  Future<DateTime> requestOtp(PhoneNumber phone) async {
    final body = await _post(ApiEndpoints.requestOtp, {
      'phone_number': phone.e164,
    });
    final expiresAt = body['expires_at'];
    final parsed = expiresAt is String ? DateTime.tryParse(expiresAt) : null;
    if (parsed == null) throw const AuthException(AuthErrorCode.badServerUrl);
    return parsed;
  }

  @override
  Future<Session> verifyOtp(PhoneNumber phone, OtpCode code) async {
    final body = await _post(ApiEndpoints.verifyOtp, {
      'phone_number': phone.e164,
      'code': code.value,
    });
    try {
      return SessionCodec.fromJson(body);
    } on FormatException {
      throw const AuthException(AuthErrorCode.badServerUrl);
    }
  }

  /// Corps JSON d'une réponse réussie. Le type demandé à Dio reste `dynamic` :
  /// sur un corps HTML (SPA servie en catch-all, page de proxy), un cast en
  /// `Map` échouerait dans Dio et ressortirait en panne réseau, alors que
  /// quelqu'un a bel et bien répondu.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AuthException(AuthErrorCode.badServerUrl);
      }
      return body;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AuthException _mapError(DioException e) {
    final response = e.response;
    if (response == null) return const AuthException(AuthErrorCode.network);

    // L'API répond toujours en JSON, erreurs comprises : un corps resté texte
    // vient de quelqu'un d'autre.
    final data = response.data;
    if (data is String && data.trim().isNotEmpty) {
      return const AuthException(AuthErrorCode.badServerUrl);
    }

    return AuthException(switch (readErrorCode(response)) {
      'invalid_phone_format' => AuthErrorCode.invalidPhone,
      'unknown_phone_number' => AuthErrorCode.accountNotFound,
      'invalid_otp' => AuthErrorCode.invalidOtp,
      'otp_expired' => AuthErrorCode.otpExpired,
      'rate_limited' => AuthErrorCode.rateLimited,
      'sms_failed' => AuthErrorCode.smsFailed,
      _ => AuthErrorCode.unknown,
    });
  }
}
