/// Raisons d'échec autour du calendrier d'un séjour, indépendantes du
/// transport. Les implémentations de `CalendarRepository` y traduisent les
/// `code` d'erreur de l'API (cf. `API.md` du dépôt api).
enum CalendarErrorCode {
  /// L'appelant n'a pas (ou plus) ce droit : un animateur sur ce qui revient
  /// à la direction.
  forbidden,

  /// Le séjour n'existe pas, ou le compte n'y a plus aucun lien.
  stayNotFound,

  /// L'événement n'existe plus.
  entryNotFound,

  /// La suggestion n'existe plus.
  suggestionNotFound,

  /// Une catégorie inconnue.
  invalidCategory,

  /// Un titre vide ou trop long, un lieu ou des notes trop longs.
  invalidDetails,

  /// Des dates ou des heures qui ne forment pas un événement du séjour.
  invalidSchedule,

  /// Ce jour n'est pas (ou plus) une occurrence de la série.
  invalidOccurrenceDay,

  /// Une suggestion qui ne tient pas, ou un message trop long.
  invalidSuggestion,

  /// La suggestion a déjà été acceptée ou refusée.
  suggestionAlreadyDecided,

  /// Le jeton a été refusé : la connexion est relancée.
  sessionExpired,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API.
  badServerUrl,

  unknown,
}

/// Échec d'une opération sur le calendrier d'un séjour.
class CalendarException implements Exception {
  final CalendarErrorCode code;

  const CalendarException(this.code);

  @override
  String toString() => 'CalendarException(${code.name})';
}
