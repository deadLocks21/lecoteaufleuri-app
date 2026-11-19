/// Raisons d'échec autour des séjours, indépendantes du transport. Les
/// implémentations de `StayRepository` y traduisent les `code` d'erreur de
/// l'API (cf. `API.md` du dépôt api).
enum StayErrorCode {
  /// L'appelant n'a pas (ou plus) ce droit.
  forbidden,

  /// Le séjour n'existe pas, ou le compte n'y a plus aucun lien.
  notFound,

  /// Nom vide ou trop long.
  invalidName,

  /// Nature (ACM ou non) pas choisie.
  invalidKind,

  /// Dates manquantes, ou fin avant le début.
  invalidDates,

  /// Le numéro saisi n'est pas un mobile français.
  invalidPhone,

  /// Aucun compte actif pour ce numéro.
  unknownPhone,

  /// Directeur ou adjoint sur un séjour hors ACM.
  notAcm,

  /// Nommer adjoint le directeur du séjour.
  alreadyDirector,

  /// Le jeton a été refusé : la connexion est relancée.
  sessionExpired,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API.
  badServerUrl,

  unknown,
}

/// Échec d'une opération sur les séjours.
class StayException implements Exception {
  final StayErrorCode code;

  const StayException(this.code);

  @override
  String toString() => 'StayException(${code.name})';
}
