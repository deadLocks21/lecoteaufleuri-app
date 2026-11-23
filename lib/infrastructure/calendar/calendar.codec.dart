import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// Forme JSON du calendrier, celle de l'API : jours `AAAA-MM-JJ`, heures
/// `HH:MM`, jours de la semaine de 1 à 7.
abstract final class CalendarCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static CalendarEntry entryFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'changes': final List<Object?> changes,
      'updated_at': final String updatedAt,
    } when id.isNotEmpty) {
      final draft = entryDraftFromJson(json);
      return CalendarEntry(
        id: id,
        category: draft.category,
        details: draft.details,
        schedule: draft.schedule,
        changes: [for (final change in changes) _change(change)],
        updatedAt: _instant(updatedAt),
      );
    }
    throw const FormatException('Calendar entry JSON is malformed');
  }

  /// Tout un événement : celui d'une réponse, ou une proposition.
  static EntryDraft entryDraftFromJson(Object? json) {
    if (json case {
      'category': final String category,
      'title': final String title,
      'place': final String place,
      'notes': final String notes,
      'starts_on': final String startsOn,
      'ends_on': final String endsOn,
    }) {
      final start = StayCodec.parseDay(startsOn);
      final end = StayCodec.parseDay(endsOn);
      if (end.isBefore(start)) {
        throw const FormatException('Calendar entry ends before it starts');
      }
      return EntryDraft(
        category: _category(category),
        details: EntryDetails(title: title, place: place, notes: notes),
        schedule: EntrySchedule(
          startsOn: start,
          endsOn: end,
          startTime: _time(json['start_time']),
          endTime: _time(json['end_time']),
          weekdays: switch (json['weekdays']) {
            null => null,
            final List<Object?> days => [
              for (final day in days)
                day is int && day >= 1 && day <= 7
                    ? day
                    : throw const FormatException('Weekday out of 1-7'),
            ],
            _ => throw const FormatException('Weekdays should be a list'),
          },
        ),
      );
    }
    throw const FormatException('Calendar entry draft JSON is malformed');
  }

  static OccurrenceDraft occurrenceDraftFromJson(Object? json) {
    if (json case {
      'title': final String title,
      'place': final String place,
      'notes': final String notes,
    }) {
      return OccurrenceDraft(
        details: EntryDetails(title: title, place: place, notes: notes),
        startTime: _time(json['start_time']),
        endTime: _time(json['end_time']),
      );
    }
    throw const FormatException('Occurrence draft JSON is malformed');
  }

  static CalendarSuggestion suggestionFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'kind': final String kind,
      'status': final String status,
      'message': final String message,
      'response': final String response,
      'mine': final bool mine,
      'created_at': final String createdAt,
    } when id.isNotEmpty) {
      final proposal = json['proposal'];
      return CalendarSuggestion(
        id: id,
        kind: switch (kind) {
          'add' => SuggestionKind.add,
          'change' => SuggestionKind.change,
          'cancel' => SuggestionKind.cancel,
          _ => throw const FormatException('Unknown suggestion kind'),
        },
        status: switch (status) {
          'pending' => SuggestionStatus.pending,
          'accepted' => SuggestionStatus.accepted,
          'declined' => SuggestionStatus.declined,
          _ => throw const FormatException('Unknown suggestion status'),
        },
        entryId: _optionalString(json['entry_id']),
        occurrenceDay: switch (json['occurrence_day']) {
          null => null,
          final String day => StayCodec.parseDay(day),
          _ => throw const FormatException('Occurrence day is malformed'),
        },
        targetTitle: _optionalString(json['target_title']),
        proposal: switch (proposal) {
          null => null,
          {'category': _} => entryDraftFromJson(proposal),
          _ => occurrenceDraftFromJson(proposal),
        },
        message: message,
        response: response,
        author: switch (json['author']) {
          null => null,
          {
            'id': final String id,
            'first_name': final String firstName,
            'last_name': final String lastName,
          } =>
            SuggestionAuthor(id: id, firstName: firstName, lastName: lastName),
          _ => throw const FormatException('Suggestion author is malformed'),
        },
        mine: mine,
        createdAt: _instant(createdAt),
        decidedAt: switch (json['decided_at']) {
          null => null,
          final String at => _instant(at),
          _ => throw const FormatException('Decision date is malformed'),
        },
      );
    }
    throw const FormatException('Calendar suggestion JSON is malformed');
  }

  /// Le corps d'un événement envoyé à l'API.
  static Map<String, Object?> draftToJson(CalendarDraft draft) =>
      switch (draft) {
        EntryDraft(:final category, :final details, :final schedule) => {
          'category': category.name,
          ..._details(details),
          'starts_on': StayCodec.formatDay(schedule.startsOn),
          'ends_on': StayCodec.formatDay(schedule.endsOn),
          'start_time': schedule.startTime?.format(),
          'end_time': schedule.endTime?.format(),
          'weekdays': schedule.weekdays,
        },
        OccurrenceDraft(:final details, :final startTime, :final endTime) => {
          ..._details(details),
          'start_time': startTime?.format(),
          'end_time': endTime?.format(),
        },
      };

  static Map<String, Object?> _details(EntryDetails details) => {
    'title': details.title,
    'place': details.place,
    'notes': details.notes,
  };

  static OccurrenceChange _change(Object? json) {
    if (json case {
      'day': final String day,
      'cancelled': final bool cancelled,
    }) {
      return OccurrenceChange(
        day: StayCodec.parseDay(day),
        draft: cancelled ? null : occurrenceDraftFromJson(json),
      );
    }
    throw const FormatException('Occurrence change JSON is malformed');
  }

  static CalendarCategory _category(String value) =>
      CalendarCategory.values.where((c) => c.name == value).firstOrNull ??
      (throw const FormatException('Unknown calendar category'));

  static ClockTime? _time(Object? value) => switch (value) {
    null => null,
    final String time => ClockTime.parse(time),
    _ => throw const FormatException('Time should be HH:MM'),
  };

  static String? _optionalString(Object? value) => switch (value) {
    null => null,
    final String text => text,
    _ => throw const FormatException('Expected a string or null'),
  };

  static DateTime _instant(String value) =>
      DateTime.tryParse(value) ??
      (throw const FormatException('Expected an ISO 8601 instant'));
}
