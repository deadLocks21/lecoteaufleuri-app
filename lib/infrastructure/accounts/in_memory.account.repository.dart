import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';

/// Comptes en mémoire (dev sans serveur, tests), avec les mêmes règles que
/// l'API : numéro unique, dernier admin protégé, compte inconnu refusé.
class InMemoryAccountRepository implements AccountRepository {
  final List<User> _users;
  int _created = 0;

  InMemoryAccountRepository([List<User>? users])
    : _users = [...(users ?? demoAccounts)];

  /// Le compte de démo (admin) et deux autres, pour essayer l'écran.
  static final demoAccounts = [
    InMemoryAuthRepository.demoUser,
    User(
      id: '0a5c0000-0000-4000-8000-000000000101',
      phoneNumber: '+33622222222',
      firstName: 'Dominique',
      lastName: 'Durand',
    ),
    User(
      id: '0a5c0000-0000-4000-8000-000000000102',
      phoneNumber: '+33633333333',
      firstName: 'Sacha',
      lastName: 'Bernard',
    ),
  ];

  @override
  Future<List<User>> list() async => [..._users]
    ..sort(
      (a, b) => '${a.lastName} ${a.firstName}'.compareTo(
        '${b.lastName} ${b.firstName}',
      ),
    );

  @override
  Future<User> create(AccountDraft draft) async {
    _requireFreeNumber(draft, exceptId: null);
    final user = User(
      id: '0a5c0000-0000-4000-8000-${(++_created).toString().padLeft(12, '9')}',
      phoneNumber: draft.phone.e164,
      firstName: draft.firstName,
      lastName: draft.lastName,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<User> update(String id, AccountDraft draft) async {
    final user = _find(id);
    _requireFreeNumber(draft, exceptId: id);
    return _replace(
      user.copyWith(
        phoneNumber: draft.phone.e164,
        firstName: draft.firstName,
        lastName: draft.lastName,
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    final user = _find(id);
    if (user.isAdmin) _requireAnotherAdmin();
    _users.remove(user);
  }

  @override
  Future<User> setAdmin(String id, {required bool admin}) async {
    final user = _find(id);
    if (!admin && user.isAdmin) _requireAnotherAdmin();
    return _replace(user.copyWith(isAdmin: admin));
  }

  @override
  Future<void> revokeSessions(String id) async => _find(id);

  User _find(String id) => _users.firstWhere(
    (user) => user.id == id,
    orElse: () => throw const AccountException(AccountErrorCode.notFound),
  );

  User _replace(User user) {
    _users[_users.indexWhere((u) => u.id == user.id)] = user;
    return user;
  }

  void _requireFreeNumber(AccountDraft draft, {required String? exceptId}) {
    if (_users.any(
      (u) => u.phoneNumber == draft.phone.e164 && u.id != exceptId,
    )) {
      throw const AccountException(AccountErrorCode.phoneTaken);
    }
  }

  void _requireAnotherAdmin() {
    if (_users.where((u) => u.isAdmin).length <= 1) {
      throw const AccountException(AccountErrorCode.lastAdmin);
    }
  }
}
