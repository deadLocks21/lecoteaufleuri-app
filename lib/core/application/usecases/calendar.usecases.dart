import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/services/calendar.repository.dart';

/// Le calendrier d'un séjour. Toute l'équipe.
class ListCalendarUseCase {
  final CalendarRepository _calendar;

  ListCalendarUseCase(this._calendar);

  Future<StayCalendarDto> execute(String stayId) async =>
      StayCalendarDto.fromDomain(await _calendar.entries(stayId));
}

/// La direction place un événement, une fois ou en série.
class CreateEntryUseCase {
  final CalendarRepository _calendar;

  CreateEntryUseCase(this._calendar);

  Future<CalendarEntryDto> execute(String stayId, EntryDraftDto draft) async =>
      CalendarEntryDto.fromDomain(
        await _calendar.create(stayId, draft.toDomain()),
      );
}

/// La direction change tout un événement (toute la série).
class UpdateEntryUseCase {
  final CalendarRepository _calendar;

  UpdateEntryUseCase(this._calendar);

  Future<CalendarEntryDto> execute(
    String stayId,
    String entryId,
    EntryDraftDto draft,
  ) async => CalendarEntryDto.fromDomain(
    await _calendar.update(stayId, entryId, draft.toDomain()),
  );
}

class DeleteEntryUseCase {
  final CalendarRepository _calendar;

  DeleteEntryUseCase(this._calendar);

  Future<void> execute(String stayId, String entryId) =>
      _calendar.delete(stayId, entryId);
}

/// Ce que la direction fait d'une seule occurrence d'une série.
enum OccurrenceAction { cancel, restore }

/// La direction modifie une occurrence ce jour-là seulement.
class ChangeOccurrenceUseCase {
  final CalendarRepository _calendar;

  ChangeOccurrenceUseCase(this._calendar);

  Future<CalendarEntryDto> execute(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceDraftDto draft,
  ) async => CalendarEntryDto.fromDomain(
    await _calendar.changeOccurrence(stayId, entryId, day, draft.toDomain()),
  );
}

/// La direction annule une occurrence ce jour-là, ou la rend à sa série.
class SetOccurrenceUseCase {
  final CalendarRepository _calendar;

  SetOccurrenceUseCase(this._calendar);

  Future<CalendarEntryDto> execute(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceAction action,
  ) async => CalendarEntryDto.fromDomain(switch (action) {
    OccurrenceAction.cancel => await _calendar.cancelOccurrence(
      stayId,
      entryId,
      day,
    ),
    OccurrenceAction.restore => await _calendar.restoreOccurrence(
      stayId,
      entryId,
      day,
    ),
  });
}

/// Les suggestions : toutes pour la direction, les siennes pour un animateur.
class ListSuggestionsUseCase {
  final CalendarRepository _calendar;

  ListSuggestionsUseCase(this._calendar);

  Future<List<CalendarSuggestionDto>> execute(String stayId) async => [
    for (final suggestion in await _calendar.suggestions(stayId))
      CalendarSuggestionDto.fromDomain(suggestion),
  ];
}

/// Un membre de l'équipe propose un ajout, un changement ou une annulation.
class SuggestUseCase {
  final CalendarRepository _calendar;

  SuggestUseCase(this._calendar);

  /// Un ajout : tout un événement.
  Future<CalendarSuggestionDto> add(
    String stayId,
    EntryDraftDto proposal, {
    String message = '',
  }) => _send(
    stayId,
    kind: SuggestionKind.add,
    proposal: proposal.toDomain(),
    message: message,
  );

  /// Un changement de tout l'événement ([proposal] : un [EntryDraftDto]) ou
  /// de l'occurrence de [occurrenceDay] (un [OccurrenceDraftDto]).
  Future<CalendarSuggestionDto> change(
    String stayId,
    String entryId, {
    DateTime? occurrenceDay,
    EntryDraftDto? entry,
    OccurrenceDraftDto? occurrence,
    String message = '',
  }) => _send(
    stayId,
    kind: SuggestionKind.change,
    entryId: entryId,
    occurrenceDay: occurrenceDay,
    proposal: occurrence?.toDomain() ?? entry?.toDomain(),
    message: message,
  );

  /// L'annulation de tout l'événement, ou de l'occurrence de
  /// [occurrenceDay].
  Future<CalendarSuggestionDto> cancel(
    String stayId,
    String entryId, {
    DateTime? occurrenceDay,
    String message = '',
  }) => _send(
    stayId,
    kind: SuggestionKind.cancel,
    entryId: entryId,
    occurrenceDay: occurrenceDay,
    message: message,
  );

  Future<CalendarSuggestionDto> _send(
    String stayId, {
    required SuggestionKind kind,
    String? entryId,
    DateTime? occurrenceDay,
    CalendarDraft? proposal,
    required String message,
  }) async => CalendarSuggestionDto.fromDomain(
    await _calendar.suggest(
      stayId,
      kind: kind,
      entryId: entryId,
      occurrenceDay: occurrenceDay,
      proposal: proposal,
      message: message.trim(),
    ),
  );
}

class WithdrawSuggestionUseCase {
  final CalendarRepository _calendar;

  WithdrawSuggestionUseCase(this._calendar);

  Future<void> execute(String stayId, String suggestionId) =>
      _calendar.withdraw(stayId, suggestionId);
}

/// La direction tranche : elle accepte (telle quelle ou ajustée), ou refuse.
class DecideSuggestionUseCase {
  final CalendarRepository _calendar;

  DecideSuggestionUseCase(this._calendar);

  Future<CalendarSuggestionDto> accept(
    String stayId,
    String suggestionId, {
    EntryDraftDto? entry,
    OccurrenceDraftDto? occurrence,
  }) async => CalendarSuggestionDto.fromDomain(
    await _calendar.accept(
      stayId,
      suggestionId,
      adjusted: occurrence?.toDomain() ?? entry?.toDomain(),
    ),
  );

  Future<CalendarSuggestionDto> decline(
    String stayId,
    String suggestionId, {
    String response = '',
  }) async => CalendarSuggestionDto.fromDomain(
    await _calendar.decline(stayId, suggestionId, response: response.trim()),
  );
}

/// Le lien d'abonnement du compte : le même tant qu'on ne le régénère pas.
class CalendarFeedUseCase {
  final CalendarRepository _calendar;

  CalendarFeedUseCase(this._calendar);

  Future<CalendarFeedDto> execute(String stayId) async =>
      CalendarFeedDto.fromDomain(await _calendar.feed(stayId));

  /// Un nouveau lien : les agendas abonnés à l'ancien ne le lisent plus.
  Future<CalendarFeedDto> renew(String stayId) async =>
      CalendarFeedDto.fromDomain(await _calendar.renewFeed(stayId));
}
