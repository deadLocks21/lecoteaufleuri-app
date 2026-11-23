import 'package:lecoteaufleuri/core/application/services/calendar_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/calendar.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar.service_provider.g.dart';

@Riverpod(keepAlive: true)
CalendarApplicationService calendarService(Ref ref) {
  final calendar = ref.watch(calendarRepositoryProvider);
  return CalendarApplicationService(
    calendar: ListCalendarUseCase(calendar),
    create: CreateEntryUseCase(calendar),
    update: UpdateEntryUseCase(calendar),
    delete: DeleteEntryUseCase(calendar),
    changeOccurrence: ChangeOccurrenceUseCase(calendar),
    setOccurrence: SetOccurrenceUseCase(calendar),
    suggestions: ListSuggestionsUseCase(calendar),
    suggest: SuggestUseCase(calendar),
    withdraw: WithdrawSuggestionUseCase(calendar),
    decide: DecideSuggestionUseCase(calendar),
    feed: CalendarFeedUseCase(calendar),
  );
}
