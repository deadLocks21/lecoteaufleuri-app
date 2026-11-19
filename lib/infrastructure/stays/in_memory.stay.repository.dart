import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';

/// Le compte connecté, vu des séjours : de quoi décider de ses droits.
typedef StayViewer = ({String id, bool isAdmin});

/// Séjours en mémoire (dev sans serveur, tests), avec les règles de l'API :
/// tri, direction réservée aux ACM, un seul directeur, un rôle par compte, et
/// les droits du compte connecté (admin, directeur ou adjoint).
class InMemoryStayRepository implements StayRepository {
  final List<Stay> _stays;
  final List<User> _accounts;

  /// Rôles par séjour, puis par compte.
  final Map<String, Map<String, StaffRole>> _staff;

  /// Le compte connecté, relu à chaque appel comme l'API relit l'appelant.
  final StayViewer Function() _viewer;
  int _created = 0;

  /// Sans [viewer], le compte de démo (admin).
  InMemoryStayRepository({
    List<Stay>? stays,
    List<User>? accounts,
    Map<String, Map<String, StaffRole>>? staff,
    StayViewer Function()? viewer,
  }) : _stays = [...(stays ?? demoStays)],
       _accounts = [...(accounts ?? InMemoryAccountRepository.demoAccounts)],
       _staff = {
         for (final MapEntry(:key, :value) in (staff ?? demoStaff).entries)
           key: {...value},
       },
       _viewer =
           viewer ??
           (() => (
             id: InMemoryAuthRepository.demoUser.id,
             isAdmin: InMemoryAuthRepository.demoUser.isAdmin,
           ));

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

  /// L'été est dirigé par Dominique Durand. Le compte de démo n'y a aucun
  /// rôle : il peut s'y nommer adjoint pour le voir dans « Mes séjours ».
  static final demoStaff = {
    '5d1e0000-0000-4000-8000-000000000001': {
      '0a5c0000-0000-4000-8000-000000000101': StaffRole.director,
    },
  };

  @override
  Future<List<Stay>> list() async => _sorted(_stays);

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

  @override
  Future<StayDetail> get(String stayId) async => _detail(_visible(stayId));

  @override
  Future<StayDetail> nameDirector(String stayId, PhoneNumber phone) async {
    final stay = _allowed(stayId, (role) => false);
    final account = _account(phone);
    _requireAcm(stay);
    final team = _team(stay);
    team.removeWhere((_, role) => role == StaffRole.director);
    team[account.id] = StaffRole.director;
    return _detail(stay);
  }

  @override
  Future<StayDetail> removeDirector(String stayId) async {
    final stay = _allowed(stayId, (role) => false);
    _team(stay).removeWhere((_, role) => role == StaffRole.director);
    return _detail(stay);
  }

  @override
  Future<StayDetail> addDeputy(String stayId, PhoneNumber phone) async {
    final stay = _allowed(stayId, (role) => role == StaffRole.director);
    final account = _account(phone);
    _requireAcm(stay);
    final team = _team(stay);
    if (team[account.id] == StaffRole.director) {
      throw const StayException(StayErrorCode.alreadyDirector);
    }
    team[account.id] = StaffRole.deputy;
    return _detail(stay);
  }

  @override
  Future<StayDetail> removeDeputy(String stayId, String accountId) async {
    final stay = _allowed(stayId, (role) => role == StaffRole.director);
    final team = _team(stay);
    if (team[accountId] == StaffRole.deputy) team.remove(accountId);
    return _detail(stay);
  }

  @override
  Future<List<MyStay>> mine() async => [
    for (final stay in _sorted(_stays))
      if (_roleOf(stay) case final StaffRole role)
        MyStay(stay: stay, role: role),
  ];

  StaffRole? _roleOf(Stay stay) => _staff[stay.id]?[_viewer().id];

  /// Le séjour, si le compte connecté peut le voir : comme l'API, il n'existe
  /// pas pour qui n'y a aucun lien.
  Stay _visible(String stayId) {
    final stay = _stays.where((s) => s.id == stayId).firstOrNull;
    if (stay == null || (!_viewer().isAdmin && _roleOf(stay) == null)) {
      throw const StayException(StayErrorCode.notFound);
    }
    return stay;
  }

  /// Le séjour, si le compte connecté est admin ou si son rôle passe [rule].
  Stay _allowed(String stayId, bool Function(StaffRole) rule) {
    final stay = _visible(stayId);
    if (!_viewer().isAdmin && !rule(_roleOf(stay)!)) {
      throw const StayException(StayErrorCode.forbidden);
    }
    return stay;
  }

  bool _can(Stay stay, bool Function(StaffRole) rule) {
    if (stay.kind != StayKind.acm) return false;
    if (_viewer().isAdmin) return true;
    final role = _roleOf(stay);
    return role != null && rule(role);
  }

  Map<String, StaffRole> _team(Stay stay) =>
      _staff.putIfAbsent(stay.id, () => {});

  User _account(PhoneNumber phone) => _accounts.firstWhere(
    (account) => account.phoneNumber == phone.e164,
    orElse: () => throw const StayException(StayErrorCode.unknownPhone),
  );

  void _requireAcm(Stay stay) {
    if (stay.kind != StayKind.acm) {
      throw const StayException(StayErrorCode.notAcm);
    }
  }

  StayDetail _detail(Stay stay) {
    TeamMember? member(String id) {
      final account = _accounts.where((a) => a.id == id).firstOrNull;
      return account == null
          ? null
          : TeamMember(
              id: account.id,
              firstName: account.firstName,
              lastName: account.lastName,
            );
    }

    final team = _staff[stay.id] ?? {};
    final directorId = team.entries
        .where((e) => e.value == StaffRole.director)
        .map((e) => e.key)
        .firstOrNull;
    final deputies =
        [
          for (final MapEntry(:key, :value) in team.entries)
            if (value == StaffRole.deputy) ?member(key),
        ]..sort(
          (a, b) => '${a.lastName} ${a.firstName}'.compareTo(
            '${b.lastName} ${b.firstName}',
          ),
        );

    return StayDetail(
      stay: stay,
      director: directorId == null ? null : member(directorId),
      deputies: deputies,
      canManageDirector: _can(stay, (role) => false),
      canManageDeputies: _can(stay, (role) => role == StaffRole.director),
    );
  }

  static List<Stay> _sorted(List<Stay> stays) => [...stays]
    ..sort((a, b) {
      final byStart = b.startsOn.compareTo(a.startsOn);
      return byStart != 0 ? byStart : a.name.compareTo(b.name);
    });
}
