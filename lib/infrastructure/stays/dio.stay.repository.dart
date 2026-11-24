import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// [StayRepository] sur HTTP : `/api/admin/stays`, `/api/stays/{id}…` et
/// `/api/me/stays` (cf. `API.md` du dépôt api). Toute erreur devient une
/// [StayException].
class DioStayRepository implements StayRepository {
  final Dio _dio;

  DioStayRepository(this._dio);

  @override
  Future<List<Stay>> list() async =>
      _list(await _send('GET', ApiEndpoints.adminStays), StayCodec.fromJson);

  @override
  Future<Stay> create(StayDraft draft) async => _decode(
    StayCodec.fromJson,
    await _send('POST', ApiEndpoints.adminStays, data: StayCodec.toJson(draft)),
  );

  @override
  Future<Stay> update(String stayId, StayDraft draft) async => _decode(
    StayCodec.fromJson,
    await _send(
      'PUT',
      ApiEndpoints.adminStay(stayId),
      data: StayCodec.toJson(draft),
    ),
  );

  @override
  Future<StayDetail> get(String stayId) async =>
      _detail(await _send('GET', ApiEndpoints.stay(stayId)));

  @override
  Future<StayDetail> nameDirector(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  }) async => _detail(
    await _send(
      'POST',
      ApiEndpoints.stayDirectors(stayId),
      data: _staff(phone, newAccount),
    ),
  );

  @override
  Future<StayDetail> removeDirector(String stayId, String accountId) async =>
      _detail(
        await _send('DELETE', ApiEndpoints.stayDirector(stayId, accountId)),
      );

  @override
  Future<StayDetail> addDeputy(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  }) async => _detail(
    await _send(
      'POST',
      ApiEndpoints.stayDeputies(stayId),
      data: _staff(phone, newAccount),
    ),
  );

  @override
  Future<StayDetail> removeDeputy(String stayId, String accountId) async =>
      _detail(
        await _send('DELETE', ApiEndpoints.stayDeputy(stayId, accountId)),
      );

  @override
  Future<StayDetail> addAnimator(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
    bool demote = false,
  }) async => _detail(
    await _send(
      'POST',
      ApiEndpoints.stayAnimators(stayId),
      data: {..._staff(phone, newAccount), if (demote) 'demote': true},
    ),
  );

  @override
  Future<StayDetail> removeAnimator(String stayId, String accountId) async =>
      _detail(
        await _send('DELETE', ApiEndpoints.stayAnimator(stayId, accountId)),
      );

  @override
  Future<List<MyStay>> mine() async =>
      _list(await _send('GET', ApiEndpoints.myStays), StayCodec.myStayFromJson);

  /// Le corps d'une nomination : le numéro, et les noms du compte à créer.
  static Map<String, dynamic> _staff(
    PhoneNumber phone,
    NewStaffAccount? newAccount,
  ) => {
    'phone_number': phone.e164,
    if (newAccount != null) ...{
      'first_name': newAccount.firstName,
      'last_name': newAccount.lastName,
    },
  };

  static StayDetail _detail(Object? json) =>
      _decode(StayCodec.detailFromJson, json);

  /// La liste `stays` d'une réponse, chaque élément lu par [decode].
  static List<T> _list<T>(
    Map<String, dynamic> body,
    T Function(Object?) decode,
  ) {
    final stays = body['stays'];
    if (stays is! List) {
      throw const StayException(StayErrorCode.badServerUrl);
    }
    return [for (final stay in stays) _decode(decode, stay)];
  }

  static T _decode<T>(T Function(Object?) decode, Object? json) {
    try {
      return decode(json);
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
      'stay_not_found' => StayErrorCode.notFound,
      'invalid_stay_name' => StayErrorCode.invalidName,
      'invalid_stay_kind' => StayErrorCode.invalidKind,
      'invalid_stay_dates' => StayErrorCode.invalidDates,
      'unknown_phone_number' => StayErrorCode.unknownPhone,
      'invalid_phone_format' => StayErrorCode.invalidPhone,
      'invalid_user_name' => StayErrorCode.invalidPersonName,
      'not_an_acm_stay' => StayErrorCode.notAcm,
      'already_director' => StayErrorCode.alreadyDirector,
      'already_deputy' => StayErrorCode.alreadyDeputy,
      'stay_has_team' => StayErrorCode.hasTeam,
      'entries_outside_stay_dates' => StayErrorCode.entriesOutsideDates,
      'invalid_token' => StayErrorCode.sessionExpired,
      _ => StayErrorCode.unknown,
    });
  }
}
