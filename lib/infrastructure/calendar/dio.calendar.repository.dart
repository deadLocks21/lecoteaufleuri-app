import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/services/calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/calendar.codec.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// [CalendarRepository] sur HTTP : `/api/stays/{id}/calendar…` (cf. `API.md`
/// du dépôt api). Toute erreur devient une [CalendarException].
class DioCalendarRepository implements CalendarRepository {
  final Dio _dio;

  DioCalendarRepository(this._dio);

  @override
  Future<List<CalendarEntry>> entries(String stayId) async => _list(
    await _send('GET', ApiEndpoints.stayCalendar(stayId)),
    'entries',
    CalendarCodec.entryFromJson,
  );

  @override
  Future<CalendarEntry> create(String stayId, EntryDraft draft) async => _entry(
    await _send(
      'POST',
      ApiEndpoints.stayCalendarEntries(stayId),
      data: CalendarCodec.draftToJson(draft),
    ),
  );

  @override
  Future<CalendarEntry> update(
    String stayId,
    String entryId,
    EntryDraft draft,
  ) async => _entry(
    await _send(
      'PUT',
      ApiEndpoints.stayCalendarEntry(stayId, entryId),
      data: CalendarCodec.draftToJson(draft),
    ),
  );

  @override
  Future<void> delete(String stayId, String entryId) =>
      _send('DELETE', ApiEndpoints.stayCalendarEntry(stayId, entryId));

  @override
  Future<CalendarEntry> changeOccurrence(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceDraft draft,
  ) async => _entry(
    await _send(
      'PUT',
      _occurrence(stayId, entryId, day),
      data: CalendarCodec.draftToJson(draft),
    ),
  );

  @override
  Future<CalendarEntry> cancelOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  ) async => _entry(await _send('DELETE', _occurrence(stayId, entryId, day)));

  @override
  Future<CalendarEntry> restoreOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  ) async => _entry(
    await _send('POST', '${_occurrence(stayId, entryId, day)}/restore'),
  );

  @override
  Future<List<CalendarSuggestion>> suggestions(String stayId) async => _list(
    await _send('GET', ApiEndpoints.stayCalendarSuggestions(stayId)),
    'suggestions',
    CalendarCodec.suggestionFromJson,
  );

  @override
  Future<CalendarSuggestion> suggest(
    String stayId, {
    required SuggestionKind kind,
    String? entryId,
    DateTime? occurrenceDay,
    CalendarDraft? proposal,
    String message = '',
  }) async => _suggestion(
    await _send(
      'POST',
      ApiEndpoints.stayCalendarSuggestions(stayId),
      data: {
        'kind': kind.name,
        'entry_id': ?entryId,
        if (occurrenceDay != null)
          'occurrence_day': StayCodec.formatDay(occurrenceDay),
        if (proposal != null) 'proposal': CalendarCodec.draftToJson(proposal),
        'message': message,
      },
    ),
  );

  @override
  Future<void> withdraw(String stayId, String suggestionId) => _send(
    'DELETE',
    ApiEndpoints.stayCalendarSuggestion(stayId, suggestionId),
  );

  @override
  Future<CalendarSuggestion> accept(
    String stayId,
    String suggestionId, {
    CalendarDraft? adjusted,
  }) async => _suggestion(
    await _send(
      'POST',
      '${ApiEndpoints.stayCalendarSuggestion(stayId, suggestionId)}/accept',
      data: {
        if (adjusted != null) 'proposal': CalendarCodec.draftToJson(adjusted),
      },
    ),
  );

  @override
  Future<CalendarSuggestion> decline(
    String stayId,
    String suggestionId, {
    String response = '',
  }) async => _suggestion(
    await _send(
      'POST',
      '${ApiEndpoints.stayCalendarSuggestion(stayId, suggestionId)}/decline',
      data: {'response': response},
    ),
  );

  @override
  Future<CalendarFeed> feed(String stayId) async =>
      _feed(await _send('GET', ApiEndpoints.stayCalendarFeed(stayId)));

  @override
  Future<CalendarFeed> renewFeed(String stayId) async => _feed(
    await _send('POST', '${ApiEndpoints.stayCalendarFeed(stayId)}/renewal'),
  );

  static String _occurrence(String stayId, String entryId, DateTime day) =>
      ApiEndpoints.stayCalendarOccurrence(
        stayId,
        entryId,
        StayCodec.formatDay(day),
      );

  static CalendarEntry _entry(Object? json) =>
      _decode(CalendarCodec.entryFromJson, json);

  static CalendarSuggestion _suggestion(Object? json) =>
      _decode(CalendarCodec.suggestionFromJson, json);

  /// Le chemin rendu par l'API, ajouté à son adresse : celle que joint
  /// l'appareil, donc aussi les agendas.
  CalendarFeed _feed(Map<String, dynamic>? body) {
    final path = body?['path'];
    final base = Uri.tryParse(_dio.options.baseUrl);
    if (path is! String || !path.startsWith('/') || base == null) {
      throw const CalendarException(CalendarErrorCode.badServerUrl);
    }
    return CalendarFeed(base.resolve(path));
  }

  static List<T> _list<T>(
    Map<String, dynamic>? body,
    String field,
    T Function(Object?) decode,
  ) {
    final items = body?[field];
    if (items is! List) {
      throw const CalendarException(CalendarErrorCode.badServerUrl);
    }
    return [for (final item in items) _decode(decode, item)];
  }

  static T _decode<T>(T Function(Object?) decode, Object? json) {
    try {
      return decode(json);
    } on FormatException {
      throw const CalendarException(CalendarErrorCode.badServerUrl);
    }
  }

  /// Corps JSON de la réponse (null pour un `204`).
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
        final Map<String, dynamic> body => body,
        null || '' when response.statusCode == 204 => null,
        _ => throw const CalendarException(CalendarErrorCode.badServerUrl),
      };
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static CalendarException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const CalendarException(CalendarErrorCode.network);
    }
    final data = response.data;
    if (data is String && data.trim().isNotEmpty) {
      return const CalendarException(CalendarErrorCode.badServerUrl);
    }
    return CalendarException(switch (readErrorCode(response)) {
      'forbidden' => CalendarErrorCode.forbidden,
      'stay_not_found' => CalendarErrorCode.stayNotFound,
      'entry_not_found' => CalendarErrorCode.entryNotFound,
      'suggestion_not_found' => CalendarErrorCode.suggestionNotFound,
      'invalid_entry_category' => CalendarErrorCode.invalidCategory,
      'invalid_entry_details' => CalendarErrorCode.invalidDetails,
      'invalid_entry_schedule' => CalendarErrorCode.invalidSchedule,
      'invalid_occurrence_day' => CalendarErrorCode.invalidOccurrenceDay,
      'invalid_suggestion' => CalendarErrorCode.invalidSuggestion,
      'suggestion_already_decided' =>
        CalendarErrorCode.suggestionAlreadyDecided,
      'invalid_token' => CalendarErrorCode.sessionExpired,
      _ => CalendarErrorCode.unknown,
    });
  }
}
