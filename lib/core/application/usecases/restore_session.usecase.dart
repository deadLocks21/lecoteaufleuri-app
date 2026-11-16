import 'package:lecoteaufleuri/core/application/dtos/session.dto.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';

/// Reprend au démarrage la session enregistrée, si elle est encore valable.
/// Une session expirée est effacée : l'utilisateur repasse par la connexion.
class RestoreSessionUseCase {
  final SessionRepository _sessions;
  final DateTime Function() _now;

  RestoreSessionUseCase(this._sessions, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  Future<SessionDto?> execute() async {
    final session = await _sessions.read();
    if (session == null) return null;
    if (session.isExpiredAt(_now())) {
      await _sessions.clear();
      return null;
    }
    return SessionDto.fromDomain(session);
  }
}
