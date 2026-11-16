import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Transport HTTP de test : enregistre les requêtes et répond par [respond].
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  ResponseBody Function(RequestOptions request) respond;

  FakeHttpAdapter(this.respond);

  /// Réponse JSON (corps encodé, `content-type` JSON).
  static ResponseBody json(Object body, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  /// Réponse HTML, comme une SPA servie en catch-all ou une page de proxy.
  static ResponseBody html({int status = 200}) => ResponseBody.fromString(
    '<!doctype html><title>Pas l\'API</title>',
    status,
    headers: {
      Headers.contentTypeHeader: ['text/html'],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Un `Dio` branché sur [adapter], réglé comme celui de l'app.
Dio dioWith(FakeHttpAdapter adapter) => Dio(
  BaseOptions(
    baseUrl: 'http://api.test',
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  ),
)..httpClientAdapter = adapter;
