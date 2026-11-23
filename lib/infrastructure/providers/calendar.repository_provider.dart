import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/services/calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/dio.calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/calendar/in_memory.calendar.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar.repository_provider.g.dart';

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, calendrier de
/// démo en mémoire sinon. En mémoire, les droits suivent le compte connecté
/// et son rôle dans les séjours de démo, comme l'API les tire de l'appelant.
@Riverpod(keepAlive: true)
CalendarRepository calendarRepository(Ref ref) {
  if (isInMemoryMode(ref.watch(apiBaseUrlProvider))) {
    final stays = ref.watch(stayRepositoryProvider);
    final memory = stays is InMemoryStayRepository ? stays : null;
    return InMemoryCalendarRepository(
      viewer: () => switch (ref.read(sessionControllerProvider)) {
        Authenticated(:final session) => (
          id: session.user.id,
          isAdmin: session.user.isAdmin,
        ),
        _ => (id: '', isAdmin: false),
      },
      roleOf: (stayId, accountId) => memory?.roleIn(stayId, accountId),
      stayOf: (stayId) => memory?.stayById(stayId),
      authorOf: (accountId) => switch (memory?.accountById(accountId)) {
        final account? => SuggestionAuthor(
          id: account.id,
          firstName: account.firstName,
          lastName: account.lastName,
        ),
        null => null,
      },
      demo: true,
    );
  }
  return DioCalendarRepository(ref.watch(dioProvider));
}
