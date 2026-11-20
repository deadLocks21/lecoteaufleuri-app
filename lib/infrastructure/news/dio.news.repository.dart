import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/services/news.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/news/news.codec.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// [NewsRepository] sur HTTP : `/api/stays/{id}/photos…`, `/days…` et `/news`
/// (cf. `API.md` du dépôt api). Toute erreur devient une [NewsException].
class DioNewsRepository implements NewsRepository {
  final Dio _dio;

  DioNewsRepository(this._dio);

  @override
  Future<List<StayPhoto>> photos(String stayId) async => _list(
    await _send('GET', ApiEndpoints.stayPhotos(stayId)),
    'photos',
    NewsCodec.photoFromJson,
  );

  @override
  Future<StayPhoto> upload(String stayId, PickedPhoto photo) async => _decode(
    NewsCodec.photoFromJson,
    await _send(
      'POST',
      ApiEndpoints.stayPhotos(stayId),
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
      }),
      // Une photo de quelques Mo sur le réseau d'un séjour peut traîner.
      timeout: const Duration(minutes: 2),
    ),
  );

  @override
  Future<StayPhoto> sort(
    String stayId,
    String photoId,
    PhotoSorting sorting,
  ) async => _decode(
    NewsCodec.photoFromJson,
    await _send(
      'PUT',
      ApiEndpoints.stayPhotoSorting(stayId, photoId),
      data: {'sorting': NewsCodec.sortingToJson(sorting)},
    ),
  );

  @override
  Future<void> deletePhoto(String stayId, String photoId) =>
      _send('DELETE', ApiEndpoints.stayPhoto(stayId, photoId));

  @override
  Future<Uint8List> image(String stayId, String photoId, PhotoSize size) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.stayPhotoImage(stayId, photoId),
        queryParameters: {'size': size.name},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const NewsException(NewsErrorCode.badServerUrl);
      }
      return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<NewsDay>> days(String stayId) async => _list(
    await _send('GET', ApiEndpoints.stayDays(stayId)),
    'days',
    NewsCodec.dayFromJson,
  );

  @override
  Future<NewsDay> createDay(
    String stayId,
    DateTime date, {
    String summary = '',
  }) async => _day(
    await _send(
      'POST',
      ApiEndpoints.stayDays(stayId),
      data: {'date': StayCodec.formatDay(date), 'summary': summary},
    ),
  );

  @override
  Future<NewsDay> updateDay(
    String stayId,
    String dayId, {
    required DateTime date,
    required String summary,
  }) async => _day(
    await _send(
      'PUT',
      ApiEndpoints.stayDay(stayId, dayId),
      data: {'date': StayCodec.formatDay(date), 'summary': summary},
    ),
  );

  @override
  Future<void> deleteDay(String stayId, String dayId) =>
      _send('DELETE', ApiEndpoints.stayDay(stayId, dayId));

  @override
  Future<NewsDay> setDayPhotos(
    String stayId,
    String dayId,
    List<String> photoIds,
  ) async => _day(
    await _send(
      'PUT',
      ApiEndpoints.stayDayPhotos(stayId, dayId),
      data: {'photo_ids': photoIds},
    ),
  );

  @override
  Future<NewsDay> publishDay(
    String stayId,
    String dayId, {
    DateTime? at,
  }) async => _day(
    await _send(
      'PUT',
      ApiEndpoints.stayDayPublication(stayId, dayId),
      data: {if (at != null) 'publish_at': NewsCodec.instantToJson(at)},
    ),
  );

  @override
  Future<NewsDay> unpublishDay(String stayId, String dayId) async => _day(
    await _send('DELETE', ApiEndpoints.stayDayPublication(stayId, dayId)),
  );

  @override
  Future<List<PublishedDay>> news(String stayId) async => _list(
    await _send('GET', ApiEndpoints.stayNews(stayId)),
    'days',
    NewsCodec.publishedFromJson,
  );

  static NewsDay _day(Object? json) => _decode(NewsCodec.dayFromJson, json);

  /// La liste [field] d'une réponse, chaque élément lu par [decode].
  static List<T> _list<T>(
    Map<String, dynamic>? body,
    String field,
    T Function(Object?) decode,
  ) {
    final items = body?[field];
    if (items is! List) {
      throw const NewsException(NewsErrorCode.badServerUrl);
    }
    return [for (final item in items) _decode(decode, item)];
  }

  static T _decode<T>(T Function(Object?) decode, Object? json) {
    try {
      return decode(json);
    } on FormatException {
      throw const NewsException(NewsErrorCode.badServerUrl);
    }
  }

  /// Corps JSON de la réponse (null pour un `204`).
  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Object? data,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(
          method: method,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      return switch (response.data) {
        final Map<String, dynamic> body => body,
        null || '' when response.statusCode == 204 => null,
        _ => throw const NewsException(NewsErrorCode.badServerUrl),
      };
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  NewsException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const NewsException(NewsErrorCode.network);
    }

    var data = response.data;
    // Une image demandée en octets : son erreur aussi.
    if (data is List<int>) {
      try {
        data = jsonDecode(utf8.decode(data));
      } on FormatException {
        return const NewsException(NewsErrorCode.badServerUrl);
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return const NewsException(NewsErrorCode.badServerUrl);
    }

    return NewsException(switch (readErrorCode(
      Response<dynamic>(requestOptions: response.requestOptions, data: data),
    )) {
      'forbidden' => NewsErrorCode.forbidden,
      'stay_not_found' => NewsErrorCode.stayNotFound,
      'photo_not_found' => NewsErrorCode.photoNotFound,
      'day_not_found' => NewsErrorCode.dayNotFound,
      'unsupported_photo' => NewsErrorCode.unsupportedPhoto,
      'photo_too_large' => NewsErrorCode.photoTooLarge,
      'invalid_day_date' => NewsErrorCode.invalidDayDate,
      'invalid_day_summary' => NewsErrorCode.invalidSummary,
      'day_already_exists' => NewsErrorCode.dayAlreadyExists,
      'photo_in_another_day' => NewsErrorCode.photoInAnotherDay,
      'empty_day' => NewsErrorCode.emptyDay,
      'photo_storage_failed' => NewsErrorCode.storageUnavailable,
      'invalid_token' => NewsErrorCode.sessionExpired,
      _ => NewsErrorCode.unknown,
    });
  }
}
