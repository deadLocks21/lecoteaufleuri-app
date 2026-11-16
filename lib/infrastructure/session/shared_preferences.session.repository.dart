import 'dart:convert';

import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/session/session.codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session persistée dans `shared_preferences` (stockage local **non chiffré**,
/// cloisonné par app — comme songbook et motorz, pour éviter les soucis
/// d'entitlement Keychain sur macOS).
///
/// Un cache mémoire évite de relire le stockage à chaque requête HTTP (cf.
/// `AuthInterceptor`).
class SharedPreferencesSessionRepository implements SessionRepository {
  static const _key = 'lecoteaufleuri.session';

  Session? _cached;
  bool _loaded = false;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Session?> read() async {
    if (_loaded) return _cached;
    final raw = (await _prefs).getString(_key);
    _cached = raw == null ? null : _decode(raw);
    _loaded = true;
    return _cached;
  }

  @override
  Future<void> write(Session session) async {
    await (await _prefs).setString(
      _key,
      jsonEncode(SessionCodec.toJson(session)),
    );
    _cached = session;
    _loaded = true;
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await (await _prefs).remove(_key);
  }

  /// Une valeur illisible (format d'une ancienne version, stockage abîmé) vaut
  /// « pas de session » : l'utilisateur se reconnecte au lieu de rester bloqué.
  Session? _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? SessionCodec.fromJson(json) : null;
    } on FormatException {
      return null;
    }
  }
}
