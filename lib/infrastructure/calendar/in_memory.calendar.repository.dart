import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/calendar.repository.dart';

/// Le compte connecté, vu du calendrier : de quoi décider de ses droits.
typedef CalendarViewer = ({String id, bool isAdmin});

/// Calendrier en mémoire (dev sans serveur, tests), avec les règles de
/// l'API : toute l'équipe lit et propose, la direction compose et tranche,
/// un animateur ne voit que ses suggestions, chaque événement tient dans les
/// dates du séjour.
class InMemoryCalendarRepository implements CalendarRepository {
  final CalendarViewer Function() _viewer;
  final StaffRole? Function(String stayId, String accountId) _roleOf;
  final Stay? Function(String stayId) _stayOf;
  final SuggestionAuthor? Function(String accountId) _authorOf;
  final DateTime Function() _now;
  final Map<String, ({String stayId, CalendarEntry entry})> _entries = {};
  final Map<String, ({String stayId, String authorId, CalendarSuggestion s})>
  _suggestions = {};
  final Map<String, String> _feeds = {};
  int _created = 0;

  /// L'adresse des liens d'abonnement en mémoire : ils ne mènent nulle part.
  static final demoApi = Uri.https('api.lecoteaufleuri.invalid');

  /// Avec [demo], le calendrier de l'été 2027 de démo.
  InMemoryCalendarRepository({
    required CalendarViewer Function() viewer,
    required StaffRole? Function(String stayId, String accountId) roleOf,
    required Stay? Function(String stayId) stayOf,
    SuggestionAuthor? Function(String accountId)? authorOf,
    DateTime Function()? now,
    bool demo = false,
  }) : _viewer = viewer,
       _roleOf = roleOf,
       _stayOf = stayOf,
       _authorOf = authorOf ?? ((_) => null),
       _now = now ?? DateTime.now {
    if (demo) _seed();
  }

  /// L'été 2027 de démo (10-24 juillet).
  static const demoStayId = '5d1e0000-0000-4000-8000-000000000001';

  /// Sacha Bernard, qui propose deux changements.
  static const _demoAuthorId = '0a5c0000-0000-4000-8000-000000000102';

  void _seed() {
    final now = _now();
    DateTime day(int d) => DateTime.utc(2027, 7, d);
    ClockTime at(int h, [int m = 0]) => ClockTime(h, m);
    String add(
      String title,
      CalendarCategory category,
      int from,
      int to, {
      ClockTime? start,
      ClockTime? end,
      List<int>? weekdays,
      String place = '',
      String notes = '',
      List<OccurrenceChange> changes = const [],
    }) {
      final id = _nextId('ca1e');
      _entries[id] = (
        stayId: demoStayId,
        entry: CalendarEntry(
          id: id,
          category: category,
          details: EntryDetails(title: title, place: place, notes: notes),
          schedule: EntrySchedule(
            startsOn: day(from),
            endsOn: day(to),
            startTime: start,
            endTime: end,
            weekdays: weekdays,
          ),
          changes: changes,
          updatedAt: now,
        ),
      );
      return id;
    }

    const everyDay = [1, 2, 3, 4, 5, 6, 7];
    const daily = CalendarCategory.daily;
    add('Lever', daily, 11, 24, start: at(7, 45), weekdays: everyDay);
    add(
      'Petit-déjeuner',
      daily,
      11,
      24,
      start: at(8),
      end: at(9),
      weekdays: everyDay,
      place: 'Réfectoire',
      changes: [
        OccurrenceChange(
          day: day(14),
          draft: OccurrenceDraft(
            details: const EntryDetails(
              title: 'Brunch du 14 juillet',
              place: 'Terrasse',
            ),
            startTime: at(10),
            endTime: at(11, 30),
          ),
        ),
      ],
    );
    add(
      'Déjeuner',
      daily,
      11,
      23,
      start: at(12),
      end: at(13),
      weekdays: everyDay,
      place: 'Réfectoire',
    );
    add(
      'Temps calme',
      daily,
      11,
      23,
      start: at(13, 30),
      end: at(14, 30),
      weekdays: everyDay,
      changes: [
        OccurrenceChange(day: day(20)),
        OccurrenceChange(day: day(21)),
      ],
    );
    add(
      'Goûter',
      daily,
      10,
      23,
      start: at(16, 30),
      end: at(17),
      weekdays: everyDay,
    );
    add(
      'Douches',
      daily,
      10,
      23,
      start: at(18),
      end: at(19),
      weekdays: everyDay,
    );
    add(
      'Dîner',
      daily,
      10,
      23,
      start: at(19),
      end: at(20),
      weekdays: everyDay,
      place: 'Réfectoire',
    );
    add(
      'Veillée',
      daily,
      10,
      23,
      start: at(20, 30),
      end: at(21, 30),
      weekdays: everyDay,
    );
    add('Coucher', daily, 10, 23, start: at(22), weekdays: everyDay);
    add(
      'Arrivée des enfants',
      CalendarCategory.movement,
      10,
      10,
      start: at(14),
      end: at(16),
      place: 'Parking du centre',
      notes: 'Accueil des familles, remise des traitements et des fiches.',
    );
    add(
      'Départ des enfants',
      CalendarCategory.movement,
      24,
      24,
      start: at(10),
      end: at(11),
      place: 'Parking du centre',
    );
    add(
      'Arrivée d\'un animateur en renfort',
      CalendarCategory.movement,
      17,
      17,
      start: at(14),
    );
    final pool = add(
      'Piscine',
      CalendarCategory.activity,
      13,
      22,
      start: at(10),
      end: at(12),
      weekdays: [2, 4],
      place: 'Piscine municipale',
    );
    add(
      'Grand jeu',
      CalendarCategory.activity,
      13,
      13,
      start: at(14, 30),
      end: at(16, 30),
      place: 'Bois du domaine',
    );
    add(
      'Mini-camp au lac',
      CalendarCategory.activity,
      20,
      22,
      place: 'Lac de Lourdes',
      notes: 'Sacs de couchage, lampes, crème solaire.',
    );
    add(
      'Rendez-vous chez le médecin',
      CalendarCategory.incident,
      15,
      15,
      start: at(9, 30),
      end: at(10, 30),
      notes: 'Un animateur accompagne, voiture du centre.',
    );

    final crepes = _nextId('5a99');
    _suggestions[crepes] = (
      stayId: demoStayId,
      authorId: _demoAuthorId,
      s: CalendarSuggestion(
        id: crepes,
        kind: SuggestionKind.add,
        status: SuggestionStatus.pending,
        proposal: EntryDraft(
          category: CalendarCategory.activity,
          details: const EntryDetails(title: 'Soirée crêpes'),
          schedule: EntrySchedule(
            startsOn: day(18),
            endsOn: day(18),
            startTime: at(20, 30),
            endTime: at(22),
          ),
        ),
        message: 'Pour le dernier dimanche tous ensemble !',
        mine: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    );
    final skip = _nextId('5a99');
    _suggestions[skip] = (
      stayId: demoStayId,
      authorId: _demoAuthorId,
      s: CalendarSuggestion(
        id: skip,
        kind: SuggestionKind.cancel,
        status: SuggestionStatus.pending,
        entryId: pool,
        occurrenceDay: day(22),
        targetTitle: 'Piscine',
        message: 'Le mini-camp rentre ce jour-là.',
        mine: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<List<CalendarEntry>> entries(String stayId) async {
    _access(stayId);
    return [
      for (final stored in _entries.values)
        if (stored.stayId == stayId) stored.entry,
    ]..sort(_byStart);
  }

  @override
  Future<CalendarEntry> create(String stayId, EntryDraft draft) async {
    _direction(stayId);
    final id = _nextId('ca1e');
    return _store(stayId, _entry(id, _valid(stayId, draft), const []));
  }

  @override
  Future<CalendarEntry> update(
    String stayId,
    String entryId,
    EntryDraft draft,
  ) async {
    _direction(stayId);
    final current = _entryOf(stayId, entryId);
    final valid = _valid(stayId, draft);
    return _store(
      stayId,
      _entry(entryId, valid, [
        for (final change in current.changes)
          if (valid.schedule.hasOccurrenceOn(change.day)) change,
      ]),
    );
  }

  @override
  Future<void> delete(String stayId, String entryId) async {
    _direction(stayId);
    _entryOf(stayId, entryId);
    _entries.remove(entryId);
  }

  @override
  Future<CalendarEntry> changeOccurrence(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceDraft draft,
  ) async {
    _direction(stayId);
    _requireDetails(draft.details);
    if ((draft.endTime != null && draft.startTime == null) ||
        (draft.startTime != null &&
            draft.endTime != null &&
            !draft.startTime!.isBefore(draft.endTime!))) {
      throw const CalendarException(CalendarErrorCode.invalidSchedule);
    }
    return _withChange(
      stayId,
      entryId,
      day,
      OccurrenceChange(day: day, draft: draft),
    );
  }

  @override
  Future<CalendarEntry> cancelOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  ) async {
    _direction(stayId);
    return _withChange(stayId, entryId, day, OccurrenceChange(day: day));
  }

  @override
  Future<CalendarEntry> restoreOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  ) async {
    _direction(stayId);
    return _withChange(stayId, entryId, day, null);
  }

  @override
  Future<List<CalendarSuggestion>> suggestions(String stayId) async {
    final direction = _access(stayId);
    final me = _viewer().id;
    return [
      for (final stored in _suggestions.values)
        if (stored.stayId == stayId && (direction || stored.authorId == me))
          _view(stored.s, stored.authorId),
    ]..sort((a, b) {
      final pending = (a.isPending ? 0 : 1).compareTo(b.isPending ? 0 : 1);
      return pending != 0 ? pending : b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Future<CalendarSuggestion> suggest(
    String stayId, {
    required SuggestionKind kind,
    String? entryId,
    DateTime? occurrenceDay,
    CalendarDraft? proposal,
    String message = '',
  }) async {
    _access(stayId);
    String? title;
    if (kind != SuggestionKind.add) {
      if (entryId == null) {
        throw const CalendarException(CalendarErrorCode.invalidSuggestion);
      }
      final entry = _entryOf(stayId, entryId);
      if (occurrenceDay != null &&
          !entry.schedule.hasOccurrenceOn(occurrenceDay)) {
        throw const CalendarException(CalendarErrorCode.invalidOccurrenceDay);
      }
      title = entry.details.title;
    }
    final fits = switch (kind) {
      SuggestionKind.add =>
        entryId == null && occurrenceDay == null && proposal is EntryDraft,
      SuggestionKind.change =>
        occurrenceDay == null
            ? proposal is EntryDraft
            : proposal is OccurrenceDraft,
      SuggestionKind.cancel => proposal == null,
    };
    if (!fits || message.length > 2000) {
      throw const CalendarException(CalendarErrorCode.invalidSuggestion);
    }
    if (proposal is EntryDraft) _valid(stayId, proposal);
    if (proposal is OccurrenceDraft) _requireDetails(proposal.details);

    final id = _nextId('5a99');
    final me = _viewer().id;
    _suggestions[id] = (
      stayId: stayId,
      authorId: me,
      s: CalendarSuggestion(
        id: id,
        kind: kind,
        status: SuggestionStatus.pending,
        entryId: entryId,
        occurrenceDay: occurrenceDay,
        targetTitle: title,
        proposal: proposal,
        message: message.trim(),
        mine: true,
        createdAt: _now(),
      ),
    );
    return _view(_suggestions[id]!.s, me);
  }

  @override
  Future<void> withdraw(String stayId, String suggestionId) async {
    final direction = _access(stayId);
    final stored = _suggestionOf(stayId, suggestionId);
    final viewer = _viewer();
    if (stored.authorId != viewer.id && !viewer.isAdmin) {
      throw CalendarException(
        direction
            ? CalendarErrorCode.forbidden
            : CalendarErrorCode.suggestionNotFound,
      );
    }
    if (!stored.s.isPending) {
      throw const CalendarException(CalendarErrorCode.suggestionAlreadyDecided);
    }
    _suggestions.remove(suggestionId);
  }

  @override
  Future<CalendarSuggestion> accept(
    String stayId,
    String suggestionId, {
    CalendarDraft? adjusted,
  }) async {
    _direction(stayId);
    final stored = _suggestionOf(stayId, suggestionId);
    final suggestion = stored.s;
    if (!suggestion.isPending) {
      throw const CalendarException(CalendarErrorCode.suggestionAlreadyDecided);
    }
    final proposal = adjusted ?? suggestion.proposal;
    final day = suggestion.occurrenceDay;
    final entryId = suggestion.entryId;
    switch ((suggestion.kind, proposal)) {
      case (SuggestionKind.add, final EntryDraft draft):
        await create(stayId, draft);
      case (SuggestionKind.change, final EntryDraft draft)
          when entryId != null && day == null:
        await update(stayId, entryId, draft);
      case (SuggestionKind.change, final OccurrenceDraft draft)
          when entryId != null && day != null:
        await changeOccurrence(stayId, entryId, day, draft);
      case (SuggestionKind.cancel, null) when entryId != null && day == null:
        await delete(stayId, entryId);
      case (SuggestionKind.cancel, null) when entryId != null && day != null:
        await cancelOccurrence(stayId, entryId, day);
      default:
        throw const CalendarException(CalendarErrorCode.invalidSuggestion);
    }
    return _decide(stored, suggestionId, SuggestionStatus.accepted, '');
  }

  @override
  Future<CalendarSuggestion> decline(
    String stayId,
    String suggestionId, {
    String response = '',
  }) async {
    _direction(stayId);
    final stored = _suggestionOf(stayId, suggestionId);
    if (!stored.s.isPending) {
      throw const CalendarException(CalendarErrorCode.suggestionAlreadyDecided);
    }
    return _decide(
      stored,
      suggestionId,
      SuggestionStatus.declined,
      response.trim(),
    );
  }

  @override
  Future<CalendarFeed> feed(String stayId) async {
    _access(stayId);
    final key = '$stayId/${_viewer().id}';
    return _feedOf(_feeds[key] ??= _token());
  }

  @override
  Future<CalendarFeed> renewFeed(String stayId) async {
    _access(stayId);
    return _feedOf(_feeds['$stayId/${_viewer().id}'] = _token());
  }

  CalendarFeed _feedOf(String token) =>
      CalendarFeed(demoApi.resolve('/api/feeds/$token.ics'));

  String _token() => 'demo${(++_created).toString().padLeft(39, '0')}';

  CalendarSuggestion _decide(
    ({String stayId, String authorId, CalendarSuggestion s}) stored,
    String id,
    SuggestionStatus status,
    String response,
  ) {
    final s = stored.s;
    _suggestions[id] = (
      stayId: stored.stayId,
      authorId: stored.authorId,
      s: CalendarSuggestion(
        id: s.id,
        kind: s.kind,
        status: status,
        entryId: s.entryId,
        occurrenceDay: s.occurrenceDay,
        targetTitle: s.targetTitle,
        proposal: s.proposal,
        message: s.message,
        response: response,
        mine: s.mine,
        createdAt: s.createdAt,
        decidedAt: _now(),
      ),
    );
    return _view(_suggestions[id]!.s, stored.authorId);
  }

  CalendarSuggestion _view(CalendarSuggestion s, String authorId) =>
      CalendarSuggestion(
        id: s.id,
        kind: s.kind,
        status: s.status,
        entryId: s.entryId,
        occurrenceDay: s.occurrenceDay,
        targetTitle: s.targetTitle,
        proposal: s.proposal,
        message: s.message,
        response: s.response,
        author: _authorOf(authorId),
        mine: authorId == _viewer().id,
        createdAt: s.createdAt,
        decidedAt: s.decidedAt,
      );

  CalendarEntry _withChange(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceChange? change,
  ) {
    final entry = _entryOf(stayId, entryId);
    if (!entry.schedule.hasOccurrenceOn(day)) {
      throw const CalendarException(CalendarErrorCode.invalidOccurrenceDay);
    }
    return _store(
      stayId,
      _entry(entryId, entry.draft, [
        for (final other in entry.changes)
          if (other.day != day) other,
        ?change,
      ]),
    );
  }

  CalendarEntry _entry(
    String id,
    EntryDraft draft,
    List<OccurrenceChange> changes,
  ) => CalendarEntry(
    id: id,
    category: draft.category,
    details: draft.details,
    schedule: draft.schedule,
    changes: changes,
    updatedAt: _now(),
  );

  CalendarEntry _store(String stayId, CalendarEntry entry) {
    _entries[entry.id] = (stayId: stayId, entry: entry);
    return entry;
  }

  /// Le titre et les dates de [draft], dans le séjour : ce que l'API exige.
  EntryDraft _valid(String stayId, EntryDraft draft) {
    _requireDetails(draft.details);
    final stay = _stayOf(stayId)!;
    final schedule = draft.schedule;
    if (schedule.problem != null ||
        schedule.startsOn.isBefore(stay.startsOn) ||
        schedule.endsOn.isAfter(stay.endsOn)) {
      throw const CalendarException(CalendarErrorCode.invalidSchedule);
    }
    return EntryDraft(
      category: draft.category,
      details: EntryDetails(
        title: draft.details.title.trim(),
        place: draft.details.place.trim(),
        notes: draft.details.notes.trim(),
      ),
      schedule: schedule,
    );
  }

  static void _requireDetails(EntryDetails details) {
    if (details.title.trim().isEmpty ||
        details.title.trim().length > EntryDetails.titleMaxLength ||
        details.place.trim().length > EntryDetails.placeMaxLength ||
        details.notes.trim().length > EntryDetails.notesMaxLength) {
      throw const CalendarException(CalendarErrorCode.invalidDetails);
    }
  }

  CalendarEntry _entryOf(String stayId, String entryId) {
    final stored = _entries[entryId];
    if (stored == null || stored.stayId != stayId) {
      throw const CalendarException(CalendarErrorCode.entryNotFound);
    }
    return stored.entry;
  }

  ({String stayId, String authorId, CalendarSuggestion s}) _suggestionOf(
    String stayId,
    String suggestionId,
  ) {
    final stored = _suggestions[suggestionId];
    final viewer = _viewer();
    if (stored == null ||
        stored.stayId != stayId ||
        (!_isDirection(stayId) && stored.authorId != viewer.id)) {
      throw const CalendarException(CalendarErrorCode.suggestionNotFound);
    }
    return stored;
  }

  /// Toute l'équipe ; vrai pour la direction.
  bool _access(String stayId) {
    final viewer = _viewer();
    if (_stayOf(stayId) == null ||
        (!viewer.isAdmin && _roleOf(stayId, viewer.id) == null)) {
      throw const CalendarException(CalendarErrorCode.stayNotFound);
    }
    return _isDirection(stayId);
  }

  void _direction(String stayId) {
    if (!_access(stayId)) {
      throw const CalendarException(CalendarErrorCode.forbidden);
    }
  }

  bool _isDirection(String stayId) {
    final viewer = _viewer();
    final role = _roleOf(stayId, viewer.id);
    return viewer.isAdmin ||
        role == StaffRole.director ||
        role == StaffRole.deputy;
  }

  String _nextId(String prefix) =>
      '${prefix}0000-0000-4000-8000-${(++_created).toString().padLeft(12, '0')}';

  static int _byStart(CalendarEntry a, CalendarEntry b) {
    final byDay = a.schedule.startsOn.compareTo(b.schedule.startsOn);
    if (byDay != 0) return byDay;
    final byTime = (a.schedule.startTime?.minutes ?? -1).compareTo(
      b.schedule.startTime?.minutes ?? -1,
    );
    return byTime != 0 ? byTime : a.details.title.compareTo(b.details.title);
  }
}
