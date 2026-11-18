import 'package:lecoteaufleuri/core/application/dtos/session.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';

/// Relit le compte connecté auprès du serveur (`GET /api/me`) et met à jour la
/// session enregistrée : statut d'admin et, plus tard, séjours et enfants.
///
/// Rend `null` s'il n'y a plus de session, ou si elle a changé pendant
/// l'appel (déconnexion, autre compte) : on ne ressuscite rien.
class RefreshSessionUseCase {
  final AuthRepository _auth;
  final SessionRepository _sessions;

  RefreshSessionUseCase(this._auth, this._sessions);

  Future<SessionDto?> execute() async {
    final session = await _sessions.read();
    if (session == null) return null;

    final user = await _auth.currentUser();

    if ((await _sessions.read())?.token != session.token) return null;
    final refreshed = Session(
      token: session.token,
      expiresAt: session.expiresAt,
      user: user,
    );
    await _sessions.write(refreshed);
    return SessionDto.fromDomain(refreshed);
  }
}
