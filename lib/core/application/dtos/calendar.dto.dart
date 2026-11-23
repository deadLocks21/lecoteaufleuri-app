import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

/// Tout un événement, tel que l'UI l'édite, l'affiche ou le propose : jours
/// à minuit UTC, heures du séjour, jours de la semaine de 1 (lundi) à 7
/// (dimanche), nuls pour un événement unique.
class EntryDraftDto {
  final CalendarCategory category;
  final String title;
  final String place;
  final String notes;
  final DateTime startsOn;
  final DateTime endsOn;
  final ClockTime? startTime;
  final ClockTime? endTime;
  final List<int>? weekdays;

  const EntryDraftDto({
    required this.category,
    required this.title,
    this.place = '',
    this.notes = '',
    required this.startsOn,
    required this.endsOn,
    this.startTime,
    this.endTime,
    this.weekdays,
  });

  factory EntryDraftDto.fromDomain(EntryDraft draft) => EntryDraftDto(
    category: draft.category,
    title: draft.details.title,
    place: draft.details.place,
    notes: draft.details.notes,
    startsOn: draft.schedule.startsOn,
    endsOn: draft.schedule.endsOn,
    startTime: draft.schedule.startTime,
    endTime: draft.schedule.endTime,
    weekdays: draft.schedule.weekdays,
  );

  EntryDraft toDomain() => EntryDraft(
    category: category,
    details: EntryDetails(
      title: title.trim(),
      place: place.trim(),
      notes: notes.trim(),
    ),
    schedule: EntrySchedule(
      startsOn: startsOn,
      endsOn: endsOn.isBefore(startsOn) ? startsOn : endsOn,
      startTime: startTime,
      endTime: endTime,
      weekdays: weekdays,
    ),
  );

  bool get isRecurring => weekdays != null;

  /// Ce qui empêche ces dates et ces heures de former un événement, ou null.
  ScheduleProblem? get problem => endsOn.isBefore(startsOn)
      ? ScheduleProblem.endBeforeStart
      : toDomain().schedule.problem;
}

/// Une seule occurrence d'une série, telle que l'UI l'édite ou la propose.
class OccurrenceDraftDto {
  final String title;
  final String place;
  final String notes;
  final ClockTime? startTime;
  final ClockTime? endTime;

  const OccurrenceDraftDto({
    required this.title,
    this.place = '',
    this.notes = '',
    this.startTime,
    this.endTime,
  });

  factory OccurrenceDraftDto.fromDomain(OccurrenceDraft draft) =>
      OccurrenceDraftDto(
        title: draft.details.title,
        place: draft.details.place,
        notes: draft.details.notes,
        startTime: draft.startTime,
        endTime: draft.endTime,
      );

  OccurrenceDraft toDomain() => OccurrenceDraft(
    details: EntryDetails(
      title: title.trim(),
      place: place.trim(),
      notes: notes.trim(),
    ),
    startTime: startTime,
    endTime: endTime,
  );

  /// Ce qui empêche ces heures de tenir dans la journée, ou null.
  ScheduleProblem? get problem => switch ((startTime, endTime)) {
    (null, _?) => ScheduleProblem.endWithoutStart,
    (final start?, final end?) when !start.isBefore(end) =>
      ScheduleProblem.endBeforeStart,
    _ => null,
  };
}

/// Une occurrence d'une série qui s'en écarte : annulée ([draft] nul), ou
/// modifiée ce jour-là.
class OccurrenceChangeDto {
  final DateTime day;
  final OccurrenceDraftDto? draft;

  const OccurrenceChangeDto({required this.day, this.draft});

  bool get isCancelled => draft == null;
}

/// Un événement du calendrier, tel que l'équipe le lit et que la direction
/// le compose.
class CalendarEntryDto {
  final String id;
  final EntryDraftDto draft;
  final List<OccurrenceChangeDto> changes;
  final DateTime updatedAt;

  const CalendarEntryDto({
    required this.id,
    required this.draft,
    this.changes = const [],
    required this.updatedAt,
  });

  factory CalendarEntryDto.fromDomain(CalendarEntry entry) => CalendarEntryDto(
    id: entry.id,
    draft: EntryDraftDto.fromDomain(entry.draft),
    changes: [
      for (final change in entry.changes)
        OccurrenceChangeDto(
          day: change.day,
          draft: switch (change.draft) {
            final OccurrenceDraft draft => OccurrenceDraftDto.fromDomain(draft),
            null => null,
          },
        ),
    ],
    updatedAt: entry.updatedAt,
  );

  CalendarEntry toDomain() {
    final draft = this.draft.toDomain();
    return CalendarEntry(
      id: id,
      category: draft.category,
      details: draft.details,
      schedule: draft.schedule,
      changes: [
        for (final change in changes)
          OccurrenceChange(day: change.day, draft: change.draft?.toDomain()),
      ],
      updatedAt: updatedAt,
    );
  }

  bool get isRecurring => draft.isRecurring;

  /// Ce que devient l'occurrence de [day] : modifiée, annulée, ou celle de
  /// la série.
  OccurrenceChangeDto? changeOn(DateTime day) =>
      changes.where((change) => change.day == day).firstOrNull;
}

/// Ce qui a lieu un jour, tel que l'UI l'affiche.
class CalendarOccurrenceDto {
  final String entryId;
  final CalendarCategory category;
  final String title;
  final String place;
  final String notes;
  final DateTime startsOn;
  final DateTime endsOn;
  final ClockTime? startTime;
  final ClockTime? endTime;
  final bool recurring;
  final bool changed;
  final bool cancelled;

  const CalendarOccurrenceDto({
    required this.entryId,
    required this.category,
    required this.title,
    this.place = '',
    this.notes = '',
    required this.startsOn,
    required this.endsOn,
    this.startTime,
    this.endTime,
    required this.recurring,
    this.changed = false,
    this.cancelled = false,
  });

  factory CalendarOccurrenceDto.fromDomain(CalendarOccurrence occurrence) =>
      CalendarOccurrenceDto(
        entryId: occurrence.entryId,
        category: occurrence.category,
        title: occurrence.details.title,
        place: occurrence.details.place,
        notes: occurrence.details.notes,
        startsOn: occurrence.startsOn,
        endsOn: occurrence.endsOn,
        startTime: occurrence.startTime,
        endTime: occurrence.endTime,
        recurring: occurrence.recurring,
        changed: occurrence.changed,
        cancelled: occurrence.cancelled,
      );

  bool get isAllDay => startTime == null;

  bool get spansSeveralDays => endsOn != startsOn;

  /// Ce qu'on garde de l'occurrence si on la modifie seule.
  OccurrenceDraftDto get asOccurrenceDraft => OccurrenceDraftDto(
    title: title,
    place: place,
    notes: notes,
    startTime: startTime,
    endTime: endTime,
  );
}

/// Le calendrier d'un séjour : ses événements, et ce qui a lieu chaque jour.
class StayCalendarDto {
  final List<CalendarEntryDto> entries;
  final List<CalendarEntry> _domain;

  StayCalendarDto(List<CalendarEntryDto> entries)
    : entries = List.unmodifiable(entries),
      _domain = [for (final entry in entries) entry.toDomain()];

  factory StayCalendarDto.fromDomain(List<CalendarEntry> entries) =>
      StayCalendarDto([
        for (final e in entries) CalendarEntryDto.fromDomain(e),
      ]);

  CalendarEntryDto? entry(String id) =>
      entries.where((entry) => entry.id == id).firstOrNull;

  /// Ce qui a lieu le jour [day] (minuit UTC) : à la journée d'abord, puis
  /// par heure. Les occurrences annulées n'y sont qu'avec [withCancelled].
  List<CalendarOccurrenceDto> on(DateTime day, {bool withCancelled = false}) =>
      [
        for (final occurrence in occurrencesOn(
          _domain,
          day,
          withCancelled: withCancelled,
        ))
          CalendarOccurrenceDto.fromDomain(occurrence),
      ];

  /// Le même calendrier, [entry] ajouté ou remplacé.
  StayCalendarDto withEntry(CalendarEntryDto entry) => StayCalendarDto(
    [
      for (final other in entries)
        if (other.id != entry.id) other,
      entry,
    ]..sort(_byStart),
  );

  /// Le même calendrier, sans l'événement [id].
  StayCalendarDto without(String id) => StayCalendarDto([
    for (final other in entries)
      if (other.id != id) other,
  ]);

  static int _byStart(CalendarEntryDto a, CalendarEntryDto b) {
    final byDay = a.draft.startsOn.compareTo(b.draft.startsOn);
    if (byDay != 0) return byDay;
    final byTime = (a.draft.startTime?.minutes ?? -1).compareTo(
      b.draft.startTime?.minutes ?? -1,
    );
    return byTime != 0 ? byTime : a.draft.title.compareTo(b.draft.title);
  }
}

/// Une suggestion, telle que l'UI l'affiche : à la direction pour qu'elle
/// tranche, à son auteur pour qu'il en voie la suite.
class CalendarSuggestionDto {
  final String id;
  final SuggestionKind kind;
  final SuggestionStatus status;
  final String? entryId;
  final DateTime? occurrenceDay;
  final String? targetTitle;

  /// Tout un événement (un ajout, un changement de la série)…
  final EntryDraftDto? entryProposal;

  /// … ou une seule occurrence.
  final OccurrenceDraftDto? occurrenceProposal;
  final String message;
  final String response;

  /// `Prénom Nom` de qui l'a faite ; null si le compte a disparu.
  final String? authorName;
  final bool mine;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const CalendarSuggestionDto({
    required this.id,
    required this.kind,
    required this.status,
    this.entryId,
    this.occurrenceDay,
    this.targetTitle,
    this.entryProposal,
    this.occurrenceProposal,
    this.message = '',
    this.response = '',
    this.authorName,
    required this.mine,
    required this.createdAt,
    this.decidedAt,
  });

  factory CalendarSuggestionDto.fromDomain(CalendarSuggestion suggestion) =>
      CalendarSuggestionDto(
        id: suggestion.id,
        kind: suggestion.kind,
        status: suggestion.status,
        entryId: suggestion.entryId,
        occurrenceDay: suggestion.occurrenceDay,
        targetTitle: suggestion.targetTitle,
        entryProposal: switch (suggestion.proposal) {
          final EntryDraft draft => EntryDraftDto.fromDomain(draft),
          _ => null,
        },
        occurrenceProposal: switch (suggestion.proposal) {
          final OccurrenceDraft draft => OccurrenceDraftDto.fromDomain(draft),
          _ => null,
        },
        message: suggestion.message,
        response: suggestion.response,
        authorName: switch (suggestion.author) {
          final SuggestionAuthor author =>
            '${author.firstName} ${author.lastName}'.trim(),
          null => null,
        },
        mine: suggestion.mine,
        createdAt: suggestion.createdAt,
        decidedAt: suggestion.decidedAt,
      );

  bool get isPending => status == SuggestionStatus.pending;
}

/// Le lien d'abonnement du compte, et ses variantes pour iPhone et Google.
class CalendarFeedDto {
  final Uri url;
  final Uri webcal;
  final Uri googleCalendar;

  const CalendarFeedDto({
    required this.url,
    required this.webcal,
    required this.googleCalendar,
  });

  factory CalendarFeedDto.fromDomain(CalendarFeed feed) => CalendarFeedDto(
    url: feed.url,
    webcal: feed.webcal,
    googleCalendar: feed.googleCalendar,
  );
}
