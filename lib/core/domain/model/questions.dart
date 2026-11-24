/// Les questions d'un séjour (cf. `ACCES.md` du dépôt lecoteaufleuri/dev,
/// « Questions du séjour ») : la direction en garde pour elle ou les partage
/// avec l'équipe, les animateurs l'interrogent, chacun répond dans le fil.
library;

/// Qui voit une question : la direction et son auteur, ou toute l'équipe.
enum QuestionVisibility { private, public }

/// L'auteur d'une question ou d'une réponse.
class QuestionAuthor {
  final String id;
  final String firstName;
  final String lastName;

  const QuestionAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
}

/// Une réponse du fil. [author] est null quand l'API le tait (l'auteur d'une
/// question anonyme, pour un autre animateur).
class QuestionReply {
  final String id;
  final String body;
  final QuestionAuthor? author;
  final bool mine;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Renseigné pour une réponse supprimée, que seule la direction reçoit.
  final DateTime? deletedAt;

  const QuestionReply({
    required this.id,
    required this.body,
    this.author,
    required this.mine,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}

/// Une question. [replies] porte le fil quand on l'ouvre, null dans une
/// liste.
class Question {
  final String id;
  final String? categoryId;
  final String title;
  final String body;
  final QuestionVisibility visibility;
  final bool anonymous;
  final QuestionAuthor? author;
  final bool mine;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int replyCount;
  final DateTime lastActivityAt;
  final List<QuestionReply>? replies;

  const Question({
    required this.id,
    this.categoryId,
    required this.title,
    this.body = '',
    required this.visibility,
    this.anonymous = false,
    this.author,
    required this.mine,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.replyCount = 0,
    required this.lastActivityAt,
    this.replies,
  });
}

/// Une catégorie de questions, propre à un séjour.
class QuestionCategory {
  final String id;
  final String name;

  const QuestionCategory({required this.id, required this.name});
}
