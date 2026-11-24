import 'package:lecoteaufleuri/core/domain/model/questions.dart';

/// Port des questions d'un séjour (cf. `ACCES.md` du dépôt
/// lecoteaufleuri/dev, « Questions du séjour »). L'API vérifie chaque droit à
/// chaque appel ; tout échec est signalé par une `QuestionsException`.
///
/// Ce qui change une question ou son fil rend la question avec son fil.
abstract interface class QuestionsRepository {
  /// Sans leur fil : toutes pour la direction, les publiques et les siennes
  /// pour un animateur ; la plus récemment active d'abord.
  Future<List<Question>> questions(String stayId);

  /// Les questions supprimées. La direction.
  Future<List<Question>> deleted(String stayId);

  /// La question et son fil.
  Future<Question> question(String stayId, String questionId);

  /// Toute l'équipe ; [visibility] public : la direction.
  Future<Question> ask(
    String stayId, {
    required String title,
    String body,
    String? categoryId,
    QuestionVisibility visibility,
  });

  /// Son auteur.
  Future<Question> edit(
    String stayId,
    String questionId, {
    required String title,
    String body,
  });

  /// Son auteur ou la direction ; null : sans catégorie.
  Future<Question> classify(
    String stayId,
    String questionId,
    String? categoryId,
  );

  /// La direction.
  Future<Question> show(
    String stayId,
    String questionId,
    QuestionVisibility visibility, {
    bool anonymous,
  });

  /// La direction.
  Future<Question> resolve(String stayId, String questionId, bool resolved);

  /// Son auteur ou la direction : réversible.
  Future<void> delete(String stayId, String questionId);

  /// La direction.
  Future<Question> restore(String stayId, String questionId);

  /// Un directeur : définitif.
  Future<void> purge(String stayId, String questionId);

  /// La direction, ou l'auteur de la question.
  Future<Question> reply(String stayId, String questionId, String body);

  /// L'auteur de la réponse.
  Future<Question> editReply(
    String stayId,
    String questionId,
    String replyId,
    String body,
  );

  /// Son auteur ou la direction : réversible.
  Future<Question> deleteReply(
    String stayId,
    String questionId,
    String replyId,
  );

  /// La direction.
  Future<Question> restoreReply(
    String stayId,
    String questionId,
    String replyId,
  );

  /// Un directeur : définitif.
  Future<Question> purgeReply(String stayId, String questionId, String replyId);

  /// Par ordre alphabétique. Toute l'équipe.
  Future<List<QuestionCategory>> categories(String stayId);

  /// La direction, pour ce qui suit.
  Future<QuestionCategory> createCategory(String stayId, String name);

  Future<QuestionCategory> renameCategory(
    String stayId,
    String categoryId,
    String name,
  );

  /// Ses questions restent, sans catégorie.
  Future<void> deleteCategory(String stayId, String categoryId);
}
