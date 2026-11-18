import 'package:lecoteaufleuri/core/application/usecases/accounts.usecases.dart';

/// Les cas d'usage de l'administration des comptes, regroupés pour son
/// contrôleur.
class AccountsApplicationService {
  final ListAccountsUseCase list;
  final SaveAccountUseCase save;
  final DeleteAccountUseCase delete;
  final SetAccountAdminUseCase setAdmin;
  final RevokeAccountSessionsUseCase revokeSessions;

  const AccountsApplicationService({
    required this.list,
    required this.save,
    required this.delete,
    required this.setAdmin,
    required this.revokeSessions,
  });
}
