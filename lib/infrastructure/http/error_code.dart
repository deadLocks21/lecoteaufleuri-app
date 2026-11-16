import 'package:dio/dio.dart';

/// Lit le `code` machine de l'enveloppe d'erreur de l'API
/// (`{ "error": "…", "code": "machine_code" }`), sans jamais lever : `null` pour
/// tout corps qui n'a pas cette forme.
String? readErrorCode(Response<dynamic>? response) {
  final data = response?.data;
  if (data is! Map) return null;
  final code = data['code'];
  return code is String ? code : null;
}
