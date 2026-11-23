import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/services/calendar_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.service_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_calendar.controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_suggestions.controller_provider.g.dart';

/// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
/// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
/// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
/// calendrier, qu'elle vient de changer.
@riverpod
class CalendarSuggestionsController extends _$CalendarSuggestionsController {
  CalendarApplicationService get _service => ref.read(calendarServiceProvider);

  @override
  Future<List<CalendarSuggestionDto>> build(String stayId) =>
      ref.watch(calendarServiceProvider).suggestions.execute(stayId);

  Future<CalendarErrorCode?> add(
    EntryDraftDto proposal, {
    String message = '',
  }) => _run(() => _service.suggest.add(stayId, proposal, message: message));

  Future<CalendarErrorCode?> change(
    String entryId, {
    DateTime? occurrenceDay,
    EntryDraftDto? entry,
    OccurrenceDraftDto? occurrence,
    String message = '',
  }) => _run(
    () => _service.suggest.change(
      stayId,
      entryId,
      occurrenceDay: occurrenceDay,
      entry: entry,
      occurrence: occurrence,
      message: message,
    ),
  );

  Future<CalendarErrorCode?> cancel(
    String entryId, {
    DateTime? occurrenceDay,
    String message = '',
  }) => _run(
    () => _service.suggest.cancel(
      stayId,
      entryId,
      occurrenceDay: occurrenceDay,
      message: message,
    ),
  );

  Future<CalendarErrorCode?> withdraw(String suggestionId) => _run(() async {
    await _service.withdraw.execute(stayId, suggestionId);
    return null;
  }, removed: suggestionId);

  Future<CalendarErrorCode?> accept(
    String suggestionId, {
    EntryDraftDto? entry,
    OccurrenceDraftDto? occurrence,
  }) => _run(
    () => _service.decide.accept(
      stayId,
      suggestionId,
      entry: entry,
      occurrence: occurrence,
    ),
    changesCalendar: true,
  );

  Future<CalendarErrorCode?> decline(
    String suggestionId, {
    String response = '',
  }) => _run(
    () => _service.decide.decline(stayId, suggestionId, response: response),
  );

  Future<CalendarErrorCode?> _run(
    Future<CalendarSuggestionDto?> Function() action, {
    String? removed,
    bool changesCalendar = false,
  }) async {
    try {
      final suggestion = await action();
      if (ref.mounted) {
        final list = [
          for (final other in state.value ?? const <CalendarSuggestionDto>[])
            if (other.id != suggestion?.id && other.id != removed) other,
          ?suggestion,
        ]..sort(_pendingFirst);
        state = AsyncData(list);
        if (changesCalendar) {
          ref.invalidate(stayCalendarControllerProvider(stayId));
        }
      }
      return null;
    } on CalendarException catch (e) {
      if (const {
            CalendarErrorCode.suggestionNotFound,
            CalendarErrorCode.suggestionAlreadyDecided,
            CalendarErrorCode.stayNotFound,
            CalendarErrorCode.forbidden,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      // L'événement visé a disparu : le calendrier aussi est à relire.
      if (e.code == CalendarErrorCode.entryNotFound && ref.mounted) {
        ref.invalidate(stayCalendarControllerProvider(stayId));
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('suggestions : échec inattendu : $e\n$stack');
      return CalendarErrorCode.unknown;
    }
  }

  static int _pendingFirst(CalendarSuggestionDto a, CalendarSuggestionDto b) {
    final pending = (a.isPending ? 0 : 1).compareTo(b.isPending ? 0 : 1);
    return pending != 0 ? pending : b.createdAt.compareTo(a.createdAt);
  }
}
