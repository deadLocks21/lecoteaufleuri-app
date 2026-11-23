import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/services/calendar_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/calendar.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_calendar.controller_provider.g.dart';

/// Le calendrier d'un séjour, et ce que la direction y fait : placer,
/// modifier, supprimer un événement ; modifier, annuler ou rétablir une
/// seule occurrence. Chaque action rend null, ou la raison de l'échec.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
@riverpod
class StayCalendarController extends _$StayCalendarController {
  CalendarApplicationService get _service => ref.read(calendarServiceProvider);

  @override
  Future<StayCalendarDto> build(String stayId) =>
      ref.watch(calendarServiceProvider).calendar.execute(stayId);

  Future<CalendarErrorCode?> create(EntryDraftDto draft) =>
      _run(() => _service.create.execute(stayId, draft));

  Future<CalendarErrorCode?> edit(String entryId, EntryDraftDto draft) =>
      _run(() => _service.update.execute(stayId, entryId, draft));

  Future<CalendarErrorCode?> delete(String entryId) => _run(() async {
    await _service.delete.execute(stayId, entryId);
    return null;
  }, removed: entryId);

  Future<CalendarErrorCode?> changeOccurrence(
    String entryId,
    DateTime day,
    OccurrenceDraftDto draft,
  ) => _run(
    () => _service.changeOccurrence.execute(stayId, entryId, day, draft),
  );

  Future<CalendarErrorCode?> setOccurrence(
    String entryId,
    DateTime day,
    OccurrenceAction action,
  ) => _run(() => _service.setOccurrence.execute(stayId, entryId, day, action));

  Future<CalendarErrorCode?> _run(
    Future<CalendarEntryDto?> Function() action, {
    String? removed,
  }) async {
    try {
      final entry = await action();
      if (ref.mounted) {
        final current = state.value ?? StayCalendarDto(const []);
        state = AsyncData(switch ((entry, removed)) {
          (final CalendarEntryDto entry, _) => current.withEntry(entry),
          (null, final String id) => current.without(id),
          _ => current,
        });
      }
      return null;
    } on CalendarException catch (e) {
      // Événement disparu, ou droits retirés : on relit ce qu'on peut voir.
      if (const {
            CalendarErrorCode.entryNotFound,
            CalendarErrorCode.stayNotFound,
            CalendarErrorCode.forbidden,
            CalendarErrorCode.invalidOccurrenceDay,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('calendrier : échec inattendu : $e\n$stack');
      return CalendarErrorCode.unknown;
    }
  }
}
