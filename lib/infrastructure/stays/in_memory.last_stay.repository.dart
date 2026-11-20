import 'package:lecoteaufleuri/core/domain/services/last_stay.repository.dart';

/// Dernier séjour ouvert gardé en mémoire seulement (tests, dev).
class InMemoryLastStayRepository implements LastStayRepository {
  final Map<String, String> _lastByAccount;

  InMemoryLastStayRepository([Map<String, String>? lastByAccount])
    : _lastByAccount = {...?lastByAccount};

  @override
  Future<String?> read(String accountId) async => _lastByAccount[accountId];

  @override
  Future<void> write(String accountId, String stayId) async =>
      _lastByAccount[accountId] = stayId;
}
