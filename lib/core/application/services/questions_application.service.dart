import 'package:lecoteaufleuri/core/application/usecases/questions.usecases.dart';

/// Les cas d'usage des questions d'un séjour, regroupés pour leurs
/// contrôleurs.
class QuestionsApplicationService {
  final ListQuestionsUseCase list;
  final QuestionThreadUseCase thread;
  final QuestionCategoriesUseCase categories;

  const QuestionsApplicationService({
    required this.list,
    required this.thread,
    required this.categories,
  });
}
