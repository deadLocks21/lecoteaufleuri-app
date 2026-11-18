/// Raisons d'échec de l'administration des séjours, indépendantes du
/// transport. Les implémentations de `StayRepository` y traduisent les `code`
/// d'erreur de l'API (cf. `API.md` du dépôt api).
enum StayErrorCode {
  /// L'appelant n'est pas (ou plus) admin.
  forbidden,

  /// Nom vide ou trop long.
  invalidName,

  /// Nature (ACM ou non) pas choisie.
  invalidKind,

  /// Dates manquantes, ou fin avant le début.
  invalidDates,

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
