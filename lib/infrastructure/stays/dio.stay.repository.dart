import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// [StayRepository] sur HTTP : les routes `/api/admin/stays` (cf. `API.md` du
/// dépôt api). Toute erreur devient une [StayException].
class DioStayRepository implements StayRepository {
  final Dio _dio;

  DioStayRepository(this._dio);

  @override
  Future<List<Stay>> list() async {
    final stays = (await _send('GET', ApiEndpoints.adminStays))['stays'];
    if (stays is! List) {
      throw const StayException(StayErrorCode.badServerUrl);
    }
    return [for (final stay in stays) _stay(stay)];
  }

  @override
  Future<Stay> create(StayDraft draft) async => _stay(
    await _send('POST', ApiEndpoints.adminStays, data: StayCodec.toJson(draft)),
  );

  static Stay _stay(Object? json) {
    try {
      return StayCodec.fromJson(json);
    } on FormatException {
      throw const StayException(StayErrorCode.badServerUrl);
    }
  }

  /// Corps JSON de la réponse. Le type demandé à Dio reste `dynamic`, pour
  /// reconnaître un corps qui n'est pas de l'API.
  Future<Map<String, dynamic>> _send(
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
        final Map<String, dynamic> body => body,
        _ => throw const StayException(StayErrorCode.badServerUrl),
      };
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  StayException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const StayException(StayErrorCode.network);
    }

    final data = response.data;
    if (data is String && data.trim().isNotEmpty) {
      return const StayException(StayErrorCode.badServerUrl);
    }

    return StayException(switch (readErrorCode(response)) {
      'forbidden' => StayErrorCode.forbidden,
      'invalid_stay_name' => StayErrorCode.invalidName,
      'invalid_stay_kind' => StayErrorCode.invalidKind,
      'invalid_stay_dates' => StayErrorCode.invalidDates,
      'invalid_token' => StayErrorCode.sessionExpired,
      _ => StayErrorCode.unknown,
    });
  }
}
