import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';
import 'package:lecoteaufleuri/infrastructure/session/shared_preferences.session.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session.repository_provider.g.dart';

/// Une seule instance, partagée par les cas d'usage (écriture) et
/// l'intercepteur HTTP (lecture du jeton) : leur cache reste cohérent.
@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) =>
    SharedPreferencesSessionRepository();
