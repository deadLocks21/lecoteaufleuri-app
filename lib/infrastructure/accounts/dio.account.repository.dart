import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/user.codec.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';

/// [AccountRepository] sur HTTP : les routes `/api/admin/users…` (cf. `API.md`
/// du dépôt api). Toute erreur devient une [AccountException].
class DioAccountRepository implements AccountRepository {
  final Dio _dio;

  DioAccountRepository(this._dio);

  @override
  Future<List<User>> list() async {
    final users = (await _send('GET', ApiEndpoints.adminUsers))?['users'];
    if (users is! List) {
      throw const AccountException(AccountErrorCode.badServerUrl);
    }
    return [for (final user in users) _user(user)];
  }

  @override
  Future<User> create(AccountDraft draft) async =>
      _user(await _send('POST', ApiEndpoints.adminUsers, data: _json(draft)));

  @override
  Future<User> update(String id, AccountDraft draft) async =>
      _user(await _send('PUT', ApiEndpoints.adminUser(id), data: _json(draft)));

  @override
  Future<void> delete(String id) => _send('DELETE', ApiEndpoints.adminUser(id));

  @override
  Future<User> setAdmin(String id, {required bool admin}) async => _user(
    await _send(admin ? 'PUT' : 'DELETE', ApiEndpoints.adminUserAdmin(id)),
  );

  @override
  Future<void> revokeSessions(String id) =>
      _send('POST', ApiEndpoints.adminUserRevokeSessions(id));

  static Map<String, dynamic> _json(AccountDraft draft) => {
    'phone_number': draft.phone.e164,
    'first_name': draft.firstName,
    'last_name': draft.lastName,
  };

  static User _user(Object? json) {
    try {
      return UserCodec.fromJson(json);
    } on FormatException {
      throw const AccountException(AccountErrorCode.badServerUrl);
    }
  }

  /// Corps JSON de la réponse, `null` pour un `204` sans corps. Le type demandé
  /// à Dio reste `dynamic`, pour reconnaître un corps qui n'est pas de l'API.
  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
      return switch (response.data) {
        null || '' => null,
        final Map<String, dynamic> body => body,
        _ => throw const AccountException(AccountErrorCode.badServerUrl),
      };
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AccountException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const AccountException(AccountErrorCode.network);
    }

    final data = response.data;
    if (data is String && data.trim().isNotEmpty) {
      return const AccountException(AccountErrorCode.badServerUrl);
    }

    return AccountException(switch (readErrorCode(response)) {
      'forbidden' => AccountErrorCode.forbidden,
      'user_not_found' => AccountErrorCode.notFound,
      'phone_number_already_registered' => AccountErrorCode.phoneTaken,
      'invalid_phone_format' => AccountErrorCode.invalidPhone,
      'invalid_user_name' => AccountErrorCode.invalidName,
      'last_admin' => AccountErrorCode.lastAdmin,
      'invalid_token' => AccountErrorCode.sessionExpired,
      _ => AccountErrorCode.unknown,
    });
  }
}
