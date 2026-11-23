import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Ce que l'éditeur envoie : tout un événement, ou une seule occurrence, et
/// le mot pour la direction quand on propose.
typedef EditorSubmit =
    Future<CalendarErrorCode?> Function({
      EntryDraftDto? entry,
      OccurrenceDraftDto? occurrence,
      required String message,
    });

/// Compose un événement — ou une seule occurrence d'une série, avec
/// [occurrenceDay] — pour le créer, le modifier, le proposer à la direction
/// ou ajuster une proposition avant de l'accepter : les champs sont les
/// mêmes, seul [onSubmit] change.
///
/// La page se referme en rendant `true` quand [onSubmit] réussit ; l'erreur
/// s'affiche sinon, et l'on reste sur la page.
///
/// Échap (ou le retour) la referme sans rien envoyer ; si l'on a changé
/// quelque chose, on confirme d'abord qu'on le perd.
class EntryEditorPage extends StatefulWidget {
  final StayDto stay;
  final String title;
  final String submitLabel;

  /// Une ligne d'explication en tête : ce qu'on modifie, ou à qui on écrit.
  final String? intro;

  /// Tout un événement à reprendre ; nul pour en créer un.
  final EntryDraftDto? entry;

  /// Le jour de l'occurrence modifiée seule, et ce qu'elle est.
  final DateTime? occurrenceDay;
  final OccurrenceDraftDto? occurrence;

  /// Le jour proposé pour un nouvel événement, et ses heures (un créneau
  /// choisi dans la grille ; sans fin, il dure une heure).
  final DateTime? defaultDay;
  final ClockTime? defaultStartTime;
  final ClockTime? defaultEndTime;

  /// Un champ pour écrire à la direction (une suggestion).
  final bool asksMessage;
  final EditorSubmit onSubmit;

  const EntryEditorPage({
    super.key,
    required this.stay,
    required this.title,
    required this.submitLabel,
    this.intro,
    this.entry,
    this.occurrenceDay,
    this.occurrence,
    this.defaultDay,
    this.defaultStartTime,
    this.defaultEndTime,
    this.asksMessage = false,
    required this.onSubmit,
  });

  bool get editsOccurrence => occurrenceDay != null;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _notes;
  final _message = TextEditingController();

  late CalendarCategory _category;
  late bool _repeats;
  late DateTime _startsOn;
  late DateTime _endsOn;
  late Set<int> _weekdays;
  late bool _allDay;
  ClockTime? _start;
  ClockTime? _end;
  bool _busy = false;

  /// Ce que la page montrait à l'ouverture : on le compare à ce qu'elle
  /// montre en partant.
  late final String _initial;

  /// La page se referme pour de bon : envoyée, ou les changements laissés.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    final occurrence = widget.occurrence;
    _title = TextEditingController(
      text: occurrence?.title ?? entry?.title ?? '',
    );
    _place = TextEditingController(
      text: occurrence?.place ?? entry?.place ?? '',
    );
    _notes = TextEditingController(
      text: occurrence?.notes ?? entry?.notes ?? '',
    );
    _category = entry?.category ?? CalendarCategory.activity;
    _repeats = entry?.isRecurring ?? false;
    final day = _clamp(
      widget.occurrenceDay ??
          entry?.startsOn ??
          widget.defaultDay ??
          calendarDay(DateTime.now()),
    );
    _startsOn = entry?.startsOn ?? day;
    _endsOn = entry?.endsOn ?? day;
    _weekdays = {...?entry?.weekdays};
    if (_weekdays.isEmpty) _weekdays = {1, 2, 3, 4, 5, 6, 7};
    final start = widget.editsOccurrence
        ? occurrence?.startTime
        : entry?.startTime;
    final end = widget.editsOccurrence ? occurrence?.endTime : entry?.endTime;
    final isNew = entry == null && occurrence == null;
    _allDay = !isNew && start == null;
    final defaultStart = widget.defaultStartTime ?? const ClockTime(10, 0);
    _start = isNew ? defaultStart : start;
    _end = isNew
        ? widget.defaultEndTime ??
              (defaultStart.hour < 23
                  ? ClockTime(defaultStart.hour + 1, defaultStart.minute)
                  : null)
        : end;
    _initial = _snapshot;
  }

  /// Tout ce qu'on peut changer dans la page, en une valeur comparable.
  String get _snapshot => [
    _category.name,
    _title.text,
    _place.text,
    _notes.text,
    _message.text,
    _repeats,
    _startsOn,
    _endsOn,
    (_weekdays.toList()..sort()).join(','),
    _allDay,
    _start,
    _end,
  ].join('\u0000');

  bool get _dirty => _snapshot != _initial;

  /// Referme la page, après confirmation s'il y a des changements.
  Future<void> _leave() async {
    if (_dirty) {
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Abandonner les modifications ?'),
              content: const Text('Ce que vous avez saisi sera perdu.'),
              actions: [
                TextButton(
                  key: const Key('keepEditing'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Continuer'),
                ),
                FilledButton(
                  key: const Key('discardChanges'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abandonner'),
                ),
              ],
            ),
          ) ??
          false;
      if (!discard || !mounted) return;
    }
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _notes.dispose();
    _message.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime day) => day.isBefore(widget.stay.startsOn)
      ? widget.stay.startsOn
      : day.isAfter(widget.stay.endsOn)
      ? widget.stay.endsOn
      : day;

  ClockTime? get _startTime => _allDay ? null : _start;
  ClockTime? get _endTime => _allDay ? null : _end;

  EntryDraftDto get _entryDraft => EntryDraftDto(
    category: _category,
    title: _title.text,
    place: _place.text,
    notes: _notes.text,
    startsOn: _startsOn,
    endsOn: _endsOn,
    startTime: _startTime,
    endTime: _endTime,
    weekdays: _repeats ? (_weekdays.toList()..sort()) : null,
  );

  OccurrenceDraftDto get _occurrenceDraft => OccurrenceDraftDto(
    title: _title.text,
    place: _place.text,
    notes: _notes.text,
    startTime: _startTime,
    endTime: _endTime,
  );

  ScheduleProblem? get _problem =>
      widget.editsOccurrence ? _occurrenceDraft.problem : _entryDraft.problem;

  bool get _canSubmit =>
      !_busy && _title.text.trim().isNotEmpty && _problem == null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(
      entry: widget.editsOccurrence ? null : _entryDraft,
      occurrence: widget.editsOccurrence ? _occurrenceDraft : null,
      message: _message.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      setState(() => _leaving = true);
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(calendarErrorMessage(error))));
  }

  Future<DateTime?> _pickDay(DateTime initial, {DateTime? first}) async {
    final stay = widget.stay;
    DateTime local(DateTime day) => DateTime(day.year, day.month, day.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: local(first ?? stay.startsOn),
      lastDate: local(stay.endsOn),
      initialDate: local(initial.isBefore(first ?? initial) ? first! : initial),
      confirmText: 'Valider',
    );
    return picked == null ? null : calendarDay(picked);
  }

  Future<ClockTime?> _pickTime(ClockTime? initial, String help) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initial?.hour ?? 10,
        minute: initial?.minute ?? 0,
      ),
      helpText: help,
    );
    return picked == null ? null : ClockTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final problem = _problem;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                TextButton(
                  key: const Key('submitEntry'),
                  onPressed: _canSubmit ? _submit : null,
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  children: [
                    if (widget.intro case final intro?) ...[
                      Text(intro, style: muted),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      key: const Key('entryTitle'),
                      controller: _title,
                      maxLength: EntryDetails.titleMaxLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (!widget.editsOccurrence) ...[
                      const SizedBox(height: 8),
                      Text('Catégorie', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in CalendarCategory.values)
                            ChoiceChip(
                              key: Key('category-${category.name}'),
                              avatar: Icon(categoryIcon(category), size: 18),
                              label: Text(categoryLabel(category)),
                              showCheckmark: false,
                              selected: _category == category,
                              onSelected: (_) => setState(() {
                                _category = category;
                                // La vie quotidienne se répète, le plus souvent.
                                if (category == CalendarCategory.daily &&
                                    widget.entry == null &&
                                    !_repeats) {
                                  _setRepeats(true);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        key: const Key('repeatsSwitch'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Se répète'),
                        subtitle: const Text(
                          'Certains jours de la semaine, sur une période du séjour',
                        ),
                        value: _repeats,
                        onChanged: (value) =>
                            setState(() => _setRepeats(value)),
                      ),
                      if (_repeats) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (var day = 1; day <= 7; day++)
                              Tooltip(
                                message: weekdayName(day),
                                child: FilterChip(
                                  key: Key('weekday-$day'),
                                  label: Text(weekdayLetters[day - 1]),
                                  showCheckmark: false,
                                  selected: _weekdays.contains(day),
                                  onSelected: (selected) => setState(
                                    () => selected
                                        ? _weekdays.add(day)
                                        : _weekdays.remove(day),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(displayWeekdays(_weekdays.toList()), style: muted),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DayButton(
                              key: const Key('startsOn'),
                              label: _repeats ? 'Du' : 'Le',
                              day: _startsOn,
                              onTap: () async {
                                final day = await _pickDay(_startsOn);
                                if (day == null) return;
                                // Un événement d'un jour suit son jour ; une
                                // période garde sa fin tant qu'elle la suit.
                                final single =
                                    !_repeats && _endsOn == _startsOn;
                                setState(() {
                                  _startsOn = day;
                                  if (single || _endsOn.isBefore(day)) {
                                    _endsOn = day;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DayButton(
                              key: const Key('endsOn'),
                              label: _repeats ? 'Au' : 'Jusqu\'au',
                              day: _endsOn,
                              onTap: () async {
                                final day = await _pickDay(
                                  _endsOn,
                                  first: _startsOn,
                                );
                                if (day != null) setState(() => _endsOn = day);
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        'Le ${displayNewsDay(widget.occurrenceDay!).toLowerCase()} '
                        'seulement : les autres jours de la série ne changent pas.',
                        style: muted,
                      ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const Key('allDaySwitch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Toute la journée'),
                      value: _allDay,
                      onChanged: (value) => setState(() {
                        _allDay = value;
                        if (!value) _start ??= const ClockTime(10, 0);
                      }),
                    ),
                    if (!_allDay)
                      Row(
                        children: [
                          Expanded(
                            child: _TimeButton(
                              key: const Key('startTime'),
                              label: 'Début',
                              time: _start,
                              onTap: () async {
                                final time = await _pickTime(_start, 'Début');
                                if (time != null) setState(() => _start = time);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeButton(
                              key: const Key('endTime'),
                              label: 'Fin',
                              time: _end,
                              placeholder: 'Sans heure de fin',
                              onTap: () async {
                                final time = await _pickTime(
                                  _end ?? _start,
                                  'Fin',
                                );
                                if (time != null) setState(() => _end = time);
                              },
                              onClear: _end == null
                                  ? null
                                  : () => setState(() => _end = null),
                            ),
                          ),
                        ],
                      ),
                    if (problem != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        scheduleProblemMessage(problem),
                        key: const Key('scheduleProblem'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('entryPlace'),
                      controller: _place,
                      maxLength: EntryDetails.placeMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Lieu (facultatif)',
                        prefixIcon: Icon(Icons.place_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('entryNotes'),
                      controller: _notes,
                      maxLength: EntryDetails.notesMaxLength,
                      minLines: 2,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notes (facultatif)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (widget.asksMessage) ...[
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('suggestionMessage'),
                        controller: _message,
                        maxLength: 2000,
                        minLines: 2,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Un mot pour la direction (facultatif)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.submitLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setRepeats(bool repeats) {
    _repeats = repeats;
    if (repeats && _endsOn == _startsOn) {
      _endsOn = widget.stay.endsOn;
    } else if (!repeats) {
      _endsOn = _startsOn;
    }
  }
}

class _DayButton extends StatelessWidget {
  final String label;
  final DateTime day;
  final VoidCallback onTap;

  const _DayButton({
    super.key,
    required this.label,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ${displayShortDay(day)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _TimeButton extends StatelessWidget {
  final String label;
  final ClockTime? time;
  final String? placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _TimeButton({
    super.key,
    required this.label,
    required this.time,
    this.placeholder,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            time == null ? placeholder ?? label : '$label ${time!.format()}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onClear != null)
          IconButton(
            tooltip: 'Sans heure de fin',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
          )
        else
          const SizedBox(height: 40),
      ],
    ),
  );
}

/// Ce que l'on montre d'un événement dans un résumé (une suggestion) :
/// `Piscine — Mardi 13 juillet, de 10:00 à 12:00`.
String displayDraftSummary(EntryDraftDto draft) =>
    '${draft.title} — ${displayDraftWhen(draft)}';

/// Les dates d'un séjour, pour l'intro d'un éditeur.
String displayStayRange(StayDto stay) =>
    displayStayDates(stay.startsOn, stay.endsOn);
