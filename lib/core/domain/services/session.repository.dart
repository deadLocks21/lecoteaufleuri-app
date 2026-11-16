import 'package:lecoteaufleuri/core/domain/model/session.dart';

/// Persistance de la session entre deux lancements de l'app.
abstract interface class SessionRepository {
  /// La session enregistrée, ou `null` si aucune (ou illisible).
  Future<Session?> read();

  Future<void> write(Session session);

  /// Efface la session (déconnexion, jeton refusé).
  Future<void> clear();
}
