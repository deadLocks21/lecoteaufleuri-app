import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/core/domain/services/account.repository.dart';

/// Les comptes actifs, pour l'écran d'administration.
class ListAccountsUseCase {
  final AccountRepository _accounts;

  ListAccountsUseCase(this._accounts);

  Future<List<UserDto>> execute() async =>
      (await _accounts.list()).map(UserDto.fromDomain).toList();
}

/// Crée un compte ([id] absent) ou corrige celui d'[id], à partir de la saisie
/// brute : numéro normalisé, prénom et nom obligatoires.
class SaveAccountUseCase {
  final AccountRepository _accounts;

  SaveAccountUseCase(this._accounts);

  Future<UserDto> execute({
    String? id,
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) async {
    final draft = AccountDraft.parse(
      rawPhone: rawPhone,
      firstName: firstName,
      lastName: lastName,
    );
    final user = id == null
        ? await _accounts.create(draft)
        : await _accounts.update(id, draft);
    return UserDto.fromDomain(user);
  }
}

/// Supprime un compte (de façon réversible, côté serveur).
class DeleteAccountUseCase {
  final AccountRepository _accounts;

  DeleteAccountUseCase(this._accounts);

  Future<void> execute(String id) => _accounts.delete(id);
}

/// Nomme ou retire un admin.
class SetAccountAdminUseCase {
  final AccountRepository _accounts;

  SetAccountAdminUseCase(this._accounts);

  Future<UserDto> execute(String id, {required bool admin}) async =>
      UserDto.fromDomain(await _accounts.setAdmin(id, admin: admin));
}

/// Coupe toutes les sessions d'un compte.
class RevokeAccountSessionsUseCase {
  final AccountRepository _accounts;

  RevokeAccountSessionsUseCase(this._accounts);

  Future<void> execute(String id) => _accounts.revokeSessions(id);
}
