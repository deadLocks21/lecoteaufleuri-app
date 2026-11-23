import 'package:lecoteaufleuri/core/application/usecases/calendar.usecases.dart';

/// Les cas d'usage du calendrier d'un séjour, regroupés pour leurs
/// contrôleurs : la composition par la direction, les suggestions de
/// l'équipe et l'abonnement depuis un agenda.
class CalendarApplicationService {
  final ListCalendarUseCase calendar;
  final CreateEntryUseCase create;
  final UpdateEntryUseCase update;
  final DeleteEntryUseCase delete;
  final ChangeOccurrenceUseCase changeOccurrence;
  final SetOccurrenceUseCase setOccurrence;
  final ListSuggestionsUseCase suggestions;
  final SuggestUseCase suggest;
  final WithdrawSuggestionUseCase withdraw;
  final DecideSuggestionUseCase decide;
  final CalendarFeedUseCase feed;

  const CalendarApplicationService({
    required this.calendar,
    required this.create,
    required this.update,
    required this.delete,
    required this.changeOccurrence,
    required this.setOccurrence,
    required this.suggestions,
    required this.suggest,
    required this.withdraw,
    required this.decide,
    required this.feed,
  });
}
