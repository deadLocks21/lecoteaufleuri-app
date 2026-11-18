import 'package:lecoteaufleuri/core/domain/model/account_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Port d'administration des comptes, réservée aux admins (l'API le vérifie à
/// chaque appel). Tout échec est signalé par une `AccountException`.
abstract interface class AccountRepository {
  /// Les comptes actifs, par nom puis prénom.
  Future<List<User>> list();

  Future<User> create(AccountDraft draft);

  Future<User> update(String id, AccountDraft draft);

  /// Suppression réversible côté serveur : le compte ne se connecte plus.
  Future<void> delete(String id);

  Future<User> setAdmin(String id, {required bool admin});

  /// Coupe toutes les sessions du compte : il devra se reconnecter par SMS.
  Future<void> revokeSessions(String id);
}
