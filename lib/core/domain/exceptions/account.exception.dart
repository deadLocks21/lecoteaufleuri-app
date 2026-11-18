/// Raisons d'échec de l'administration des comptes, indépendantes du
/// transport. Les implémentations d'`AccountRepository` y traduisent les
/// `code` d'erreur de l'API (cf. `API.md` du dépôt api).
enum AccountErrorCode {
  /// L'appelant n'est pas (ou plus) admin.
  forbidden,

  /// Le compte n'existe plus (supprimé entre-temps).
  notFound,

  /// Le numéro est déjà celui d'un autre compte.
  phoneTaken,

  /// Le numéro saisi n'est pas un mobile français.
  invalidPhone,

  /// Prénom ou nom vide.
  invalidName,

  /// Retirer son statut au dernier admin, ou le supprimer.
  lastAdmin,

  /// Le jeton a été refusé : la connexion est relancée.
  sessionExpired,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API.
  badServerUrl,

  unknown,
}

/// Échec d'une opération sur les comptes.
class AccountException implements Exception {
  final AccountErrorCode code;

  const AccountException(this.code);

  @override
  String toString() => 'AccountException(${code.name})';
}
