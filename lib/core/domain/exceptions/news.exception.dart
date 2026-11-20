/// Raisons d'échec autour des nouvelles d'un séjour, indépendantes du
/// transport. Les implémentations de `NewsRepository` y traduisent les `code`
/// d'erreur de l'API (cf. `API.md` du dépôt api).
enum NewsErrorCode {
  /// L'appelant n'a pas (ou plus) ce droit (un animateur sur les jours).
  forbidden,

  /// Le séjour n'existe pas, ou le compte n'y a plus aucun lien.
  stayNotFound,

  /// La photo n'existe plus, ou c'est celle d'un autre animateur.
  photoNotFound,

  /// Le jour n'existe plus.
  dayNotFound,

  /// Le fichier n'est pas une photo JPEG, PNG ou WebP.
  unsupportedPhoto,

  /// La photo dépasse 10 Mo.
  photoTooLarge,

  /// La date n'est pas un jour du séjour.
  invalidDayDate,

  /// Le résumé est trop long.
  invalidSummary,

  /// Un autre jour porte déjà cette date.
  dayAlreadyExists,

  /// Une photo choisie illustre déjà un autre jour.
  photoInAnotherDay,

  /// Publier un jour sans résumé ni photo, ou vider un jour publié.
  emptyDay,

  /// Le stockage des photos n'a pas répondu : réessayer plus tard.
  storageUnavailable,

  /// Le jeton a été refusé : la connexion est relancée.
  sessionExpired,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API.
  badServerUrl,

  unknown,
}

/// Échec d'une opération sur les nouvelles d'un séjour.
class NewsException implements Exception {
  final NewsErrorCode code;

  const NewsException(this.code);

  @override
  String toString() => 'NewsException(${code.name})';
}
