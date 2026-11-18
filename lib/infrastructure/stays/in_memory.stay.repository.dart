import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';

/// Séjours en mémoire (dev sans serveur, tests), triés comme l'API.
class InMemoryStayRepository implements StayRepository {
  final List<Stay> _stays;
  int _created = 0;

  InMemoryStayRepository([List<Stay>? stays])
    : _stays = [...(stays ?? demoStays)];

  /// Deux séjours pour essayer l'écran : un ACM et un hors ACM.
  static final demoStays = [
    Stay(
      id: '5d1e0000-0000-4000-8000-000000000001',
      name: 'Été 2027 — Pyrénées',
      kind: StayKind.acm,
      startsOn: DateTime.utc(2027, 7, 10),
      endsOn: DateTime.utc(2027, 7, 24),
    ),
    Stay(
      id: '5d1e0000-0000-4000-8000-000000000002',
      name: 'Week-end des animateurs',
      kind: StayKind.other,
      startsOn: DateTime.utc(2027, 3, 13),
      endsOn: DateTime.utc(2027, 3, 14),
    ),
  ];

  @override
  Future<List<Stay>> list() async => [..._stays]
    ..sort((a, b) {
      final byStart = b.startsOn.compareTo(a.startsOn);
      return byStart != 0 ? byStart : a.name.compareTo(b.name);
    });

  @override
  Future<Stay> create(StayDraft draft) async {
    final stay = Stay(
      id: '5d1e0000-0000-4000-8000-${(++_created).toString().padLeft(12, '9')}',
      name: draft.name,
      kind: draft.kind,
      startsOn: draft.startsOn,
      endsOn: draft.endsOn,
    );
    _stays.add(stay);
    return stay;
  }
}
