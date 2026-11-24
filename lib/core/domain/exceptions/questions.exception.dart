/// Raisons d'échec autour des questions d'un séjour, indépendantes du
/// transport. Les implémentations de `QuestionsRepository` y traduisent les
/// `code` d'erreur de l'API (cf. `API.md` du dépôt api).
enum QuestionsErrorCode {
  /// L'appelant n'a pas (ou plus) ce droit.
  forbidden,

  /// Le séjour n'existe pas, ou le compte n'y a plus aucun lien.
  stayNotFound,

  /// La question n'existe plus, ou l'appelant ne la voit plus.
  questionNotFound,

  /// La réponse n'existe plus.
  replyNotFound,

  /// La catégorie n'existe plus.
  categoryNotFound,

  /// Un titre vide ou trop long, un texte trop long.
  invalidQuestion,

  /// Une réponse vide ou trop longue.
  invalidReply,

  /// Un nom de catégorie vide ou trop long.
  invalidCategory,

  /// Le séjour a déjà une catégorie de ce nom.
  categoryAlreadyExists,

  /// Le jeton a été refusé : la connexion est relancée.
  sessionExpired,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API.
  badServerUrl,

  unknown,
}

/// Échec d'une opération sur les questions d'un séjour.
class QuestionsException implements Exception {
  final QuestionsErrorCode code;

  const QuestionsException(this.code);

  @override
  String toString() => 'QuestionsException(${code.name})';
}
