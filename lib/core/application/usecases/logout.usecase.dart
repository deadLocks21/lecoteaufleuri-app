import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';

/// Ferme la session locale. Le JWT étant sans état côté serveur, il n'y a rien
/// à prévenir : il suffit de l'oublier.
class LogoutUseCase {
  final SessionRepository _sessions;

  const LogoutUseCase(this._sessions);

  Future<void> execute() => _sessions.clear();
}
