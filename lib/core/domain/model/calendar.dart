/// Le calendrier d'un séjour (cf. `ACCES.md` du dépôt lecoteaufleuri/dev,
/// « Calendrier du séjour ») : la vie quotidienne qui se répète, les arrivées
/// et départs, les imprévus et les activités.
///
/// Les jours vivent à minuit UTC (`calendarDay`) ; les heures sont celles du
/// séjour, sans fuseau, comme on les affiche au mur.
library;

/// La nature d'un événement.
enum CalendarCategory {
  /// Lever, repas, douches, coucher… : ce qui rythme les journées.
  daily,

  /// Une arrivée ou un départ : du groupe, d'un enfant, d'un animateur.
  movement,

  /// Ce qui sort de l'ordinaire de la vie quotidienne.
  incident,

  /// Une activité qu'on souhaite mener.
  activity,
}

/// Une heure de la journée, à la minute (`HH:MM`).
class ClockTime implements Comparable<ClockTime> {
  final int hour;
  final int minute;

  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour is 0 to 23'),
      assert(minute >= 0 && minute < 60, 'minute is 0 to 59');

  static final _pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// Lève une [FormatException] si [value] n'est pas une heure `HH:MM`.
  factory ClockTime.parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw FormatException('Not a HH:MM time', value);
    }
    return ClockTime(int.parse(match[1]!), int.parse(match[2]!));
  }

  int get minutes => hour * 60 + minute;

  /// `HH:MM`, la forme de l'API.
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool isBefore(ClockTime other) => minutes < other.minutes;

  @override
  int compareTo(ClockTime other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => format();
}

/// Ce qu'on lit d'un événement : un titre, et s'il le faut un lieu et des
/// notes.
class EntryDetails {
  static const titleMaxLength = 120;
  static const placeMaxLength = 120;
  static const notesMaxLength = 4000;

  final String title;
  final String place;
  final String notes;

  const EntryDetails({required this.title, this.place = '', this.notes = ''});

  @override
  bool operator ==(Object other) =>
      other is EntryDetails &&
      other.title == title &&
      other.place == place &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(title, place, notes);
}

/// Quand a lieu un événement.
///
/// - **Une fois** ([weekdays] nul) : de [startsOn] à [endsOn], à la journée
///   ([startTime] nul) ou de [startTime] le premier jour à [endTime] le
///   dernier.
/// - **En série** : chaque jour de [startsOn] à [endsOn] qui tombe un des
///   [weekdays] (1 le lundi, 7 le dimanche), de [startTime] à [endTime] ce
///   jour-là.
class EntrySchedule {
  final DateTime startsOn;
  final DateTime endsOn;
  final ClockTime? startTime;
  final ClockTime? endTime;
  final List<int>? weekdays;

  EntrySchedule({
    required this.startsOn,
    required this.endsOn,
    this.startTime,
    this.endTime,
    List<int>? weekdays,
  }) : weekdays = weekdays == null
           ? null
           : List.unmodifiable({...weekdays}.toList()..sort()),
       assert(!endsOn.isBefore(startsOn), 'an event ends after it starts');

  bool get isRecurring => weekdays != null;

  bool get isAllDay => startTime == null;

  bool get spansSeveralDays => !isRecurring && endsOn != startsOn;

  /// Les jours où commence une occurrence : chaque jour de la série, ou le
  /// premier jour d'un événement unique.
  List<DateTime> get days {
    final weekdays = this.weekdays;
    if (weekdays == null) return [startsOn];
    return [
      for (
        var day = startsOn;
        !day.isAfter(endsOn);
        day = DateTime.utc(day.year, day.month, day.day + 1)
      )
        if (weekdays.contains(day.weekday)) day,
    ];
  }

  /// Ce jour est-il celui d'une occurrence de la série ? Toujours faux pour
  /// un événement unique.
  bool hasOccurrenceOn(DateTime day) =>
      weekdays != null &&
      !day.isBefore(startsOn) &&
      !day.isAfter(endsOn) &&
      weekdays!.contains(day.weekday);

  /// Ce qui l'empêche d'être un événement (les règles de l'API), ou null.
  ScheduleProblem? get problem {
    final start = startTime;
    final end = endTime;
    if (end != null && start == null) return ScheduleProblem.endWithoutStart;
    final sameDay = isRecurring || startsOn == endsOn;
    if (sameDay && start != null && end != null && !start.isBefore(end)) {
      return ScheduleProblem.endBeforeStart;
    }
    if (!sameDay && start != null && end == null) {
      return ScheduleProblem.severalDaysWithoutEnd;
    }
    if (weekdays case final days? when days.isEmpty) {
      return ScheduleProblem.noWeekday;
    }
    if (isRecurring && days.isEmpty) return ScheduleProblem.noDay;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is EntrySchedule &&
      other.startsOn == startsOn &&
      other.endsOn == endsOn &&
      other.startTime == startTime &&
      other.endTime == endTime &&
      _sameList(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(
    startsOn,
    endsOn,
    startTime,
    endTime,
    weekdays == null ? null : Object.hashAll(weekdays!),
  );
}

/// Pourquoi des dates et des heures ne forment pas un événement.
enum ScheduleProblem {
  endWithoutStart,
  endBeforeStart,
  severalDaysWithoutEnd,
  noWeekday,
  noDay,
}

/// Ce qu'on crée, modifie ou propose : tout un événement, ou une seule
/// occurrence d'une série.
sealed class CalendarDraft {
  const CalendarDraft();

  EntryDetails get details;
}

/// Tout un événement : sa nature, ce qu'on en lit et quand il a lieu.
class EntryDraft extends CalendarDraft {
  final CalendarCategory category;
  @override
  final EntryDetails details;
  final EntrySchedule schedule;

  const EntryDraft({
    required this.category,
    required this.details,
    required this.schedule,
  });

  @override
  bool operator ==(Object other) =>
      other is EntryDraft &&
      other.category == category &&
      other.details == details &&
      other.schedule == schedule;

  @override
  int get hashCode => Object.hash(category, details, schedule);
}

/// Une seule occurrence d'une série : ce qu'on en lit et ses heures, le même
/// jour (sans heure : à la journée).
class OccurrenceDraft extends CalendarDraft {
  @override
  final EntryDetails details;
  final ClockTime? startTime;
  final ClockTime? endTime;

  const OccurrenceDraft({required this.details, this.startTime, this.endTime});

  @override
  bool operator ==(Object other) =>
      other is OccurrenceDraft &&
      other.details == details &&
      other.startTime == startTime &&
      other.endTime == endTime;

  @override
  int get hashCode => Object.hash(details, startTime, endTime);
}

/// Une occurrence d'une série qui s'en écarte : annulée ([draft] nul), ou
/// modifiée ce jour-là seulement.
class OccurrenceChange {
  final DateTime day;
  final OccurrenceDraft? draft;

  const OccurrenceChange({required this.day, this.draft});

  bool get isCancelled => draft == null;
}

/// Un événement du calendrier d'un séjour.
class CalendarEntry {
  final String id;
  final CalendarCategory category;
  final EntryDetails details;
  final EntrySchedule schedule;

  /// Les occurrences de la série qui s'en écartent, par jour croissant.
  final List<OccurrenceChange> changes;
  final DateTime updatedAt;

  CalendarEntry({
    required this.id,
    required this.category,
    required this.details,
    required this.schedule,
    List<OccurrenceChange> changes = const [],
    required this.updatedAt,
  }) : changes = List.unmodifiable(
         [...changes]..sort((a, b) => a.day.compareTo(b.day)),
       ),
       assert(id.isNotEmpty, 'id cannot be empty');

  EntryDraft get draft =>
      EntryDraft(category: category, details: details, schedule: schedule);

  OccurrenceChange? changeOn(DateTime day) =>
      changes.where((change) => change.day == day).firstOrNull;

  /// Ce qui a lieu, dans l'ordre des jours : l'événement unique, ou chaque
  /// occurrence de la série avec ses modifications. Les occurrences annulées
  /// n'y sont qu'avec [withCancelled] (pour la direction, qui les rétablit).
  List<CalendarOccurrence> occurrences({bool withCancelled = false}) => [
    for (final day in schedule.days)
      if (changeOn(day) case final change
          when withCancelled || change == null || !change.isCancelled)
        CalendarOccurrence(
          entryId: id,
          category: category,
          details: change?.draft?.details ?? details,
          startsOn: day,
          endsOn: schedule.isRecurring ? day : schedule.endsOn,
          startTime: change?.draft == null
              ? schedule.startTime
              : change!.draft!.startTime,
          endTime: change?.draft == null
              ? schedule.endTime
              : change!.draft!.endTime,
          recurring: schedule.isRecurring,
          changed: change?.draft != null,
          cancelled: change?.isCancelled ?? false,
        ),
  ];
}

/// Ce qui a lieu un jour : un événement unique, ou un jour de sa série.
class CalendarOccurrence {
  final String entryId;
  final CalendarCategory category;
  final EntryDetails details;
  final DateTime startsOn;
  final DateTime endsOn;
  final ClockTime? startTime;
  final ClockTime? endTime;

  /// Un jour d'une série.
  final bool recurring;

  /// Modifié ce jour-là seulement.
  final bool changed;

  /// Annulé ce jour-là seulement (vu de la direction).
  final bool cancelled;

  const CalendarOccurrence({
    required this.entryId,
    required this.category,
    required this.details,
    required this.startsOn,
    required this.endsOn,
    this.startTime,
    this.endTime,
    required this.recurring,
    this.changed = false,
    this.cancelled = false,
  });

  /// A-t-il lieu ce jour-là (un événement sur plusieurs jours, chacun) ?
  bool isOn(DateTime day) => !day.isBefore(startsOn) && !day.isAfter(endsOn);
}

/// Toutes les occurrences de [entries] qui ont lieu le jour [day] : à la
/// journée d'abord, puis par heure de début, puis par titre.
List<CalendarOccurrence> occurrencesOn(
  Iterable<CalendarEntry> entries,
  DateTime day, {
  bool withCancelled = false,
}) =>
    [
      for (final entry in entries)
        for (final occurrence in entry.occurrences(
          withCancelled: withCancelled,
        ))
          if (occurrence.isOn(day)) occurrence,
    ]..sort((a, b) {
      final allDay = (a.startsOn == day && a.startTime != null ? 1 : 0)
          .compareTo(b.startsOn == day && b.startTime != null ? 1 : 0);
      if (allDay != 0) return allDay;
      final byTime = (a.startsOn == day ? a.startTime?.minutes ?? -1 : -1)
          .compareTo(b.startsOn == day ? b.startTime?.minutes ?? -1 : -1);
      return byTime != 0 ? byTime : a.details.title.compareTo(b.details.title);
    });

/// Ce que propose une suggestion.
enum SuggestionKind { add, change, cancel }

/// Où en est une suggestion.
enum SuggestionStatus { pending, accepted, declined }

/// Qui a fait une suggestion, tel que la direction le voit.
class SuggestionAuthor {
  final String id;
  final String firstName;
  final String lastName;

  const SuggestionAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
}

/// Ce qu'un membre de l'équipe propose à la direction : un ajout, un
/// changement ou une annulation d'un événement ([entryId]), de toute sa
/// série ou d'une seule occurrence ([occurrenceDay]).
class CalendarSuggestion {
  final String id;
  final SuggestionKind kind;
  final SuggestionStatus status;
  final String? entryId;
  final DateTime? occurrenceDay;

  /// Le titre de l'événement visé au moment de la suggestion.
  final String? targetTitle;
  final CalendarDraft? proposal;
  final String message;
  final String response;
  final SuggestionAuthor? author;
  final bool mine;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const CalendarSuggestion({
    required this.id,
    required this.kind,
    required this.status,
    this.entryId,
    this.occurrenceDay,
    this.targetTitle,
    this.proposal,
    this.message = '',
    this.response = '',
    this.author,
    required this.mine,
    required this.createdAt,
    this.decidedAt,
  });

  bool get isPending => status == SuggestionStatus.pending;
}

/// Le lien d'abonnement d'un compte au calendrier d'un séjour, pour Google
/// Agenda, Calendrier sur iPhone…
class CalendarFeed {
  /// L'adresse `https://…/api/feeds/….ics`.
  final Uri url;

  const CalendarFeed(this.url);

  /// La même en `webcal://`, qui ouvre l'abonnement sur iPhone et Mac.
  Uri get webcal => url.replace(scheme: 'webcal');

  /// Le lien qui propose l'abonnement dans Google Agenda.
  Uri get googleCalendar => Uri.https('calendar.google.com', '/calendar/r', {
    'cid': webcal.toString(),
  });
}

bool _sameList(List<int>? a, List<int>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
