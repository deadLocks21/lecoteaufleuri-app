import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/services/questions.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/questions/dio.questions.repository.dart';
import 'package:lecoteaufleuri/infrastructure/questions/in_memory.questions.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'questions.repository_provider.g.dart';

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, questions de démo
/// en mémoire sinon. En mémoire, les droits suivent le compte connecté et son
/// rôle dans les séjours de démo, comme l'API les tire de l'appelant.
@Riverpod(keepAlive: true)
QuestionsRepository questionsRepository(Ref ref) {
  if (isInMemoryMode(ref.watch(apiBaseUrlProvider))) {
    final stays = ref.watch(stayRepositoryProvider);
    final memory = stays is InMemoryStayRepository ? stays : null;
    return InMemoryQuestionsRepository(
      viewer: () => switch (ref.read(sessionControllerProvider)) {
        Authenticated(:final session) => (
          id: session.user.id,
          isAdmin: session.user.isAdmin,
        ),
        _ => (id: '', isAdmin: false),
      },
      roleOf: (stayId, accountId) => memory?.roleIn(stayId, accountId),
      authorOf: (accountId) => switch (memory?.accountById(accountId)) {
        final account? => QuestionAuthor(
          id: account.id,
          firstName: account.firstName,
          lastName: account.lastName,
        ),
        null => null,
      },
      demo: true,
    );
  }
  return DioQuestionsRepository(ref.watch(dioProvider));
}
