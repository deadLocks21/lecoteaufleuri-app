import 'package:lecoteaufleuri/core/application/services/questions_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/questions.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/questions.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'questions.service_provider.g.dart';

@Riverpod(keepAlive: true)
QuestionsApplicationService questionsService(Ref ref) {
  final questions = ref.watch(questionsRepositoryProvider);
  return QuestionsApplicationService(
    list: ListQuestionsUseCase(questions),
    thread: QuestionThreadUseCase(questions),
    categories: QuestionCategoriesUseCase(questions),
  );
}
