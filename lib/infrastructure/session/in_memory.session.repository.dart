import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';

/// Session gardée en mémoire seulement (tests, dev) : perdue au redémarrage.
class InMemorySessionRepository implements SessionRepository {
  Session? _session;

  InMemorySessionRepository([this._session]);

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> write(Session session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
