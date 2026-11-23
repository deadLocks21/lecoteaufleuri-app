import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar_suggestions.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_calendar.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/entry_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/time_grid.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';

/// Le calendrier d'un séjour, jour par jour : un jour à la fois sur
/// téléphone (on glisse pour changer de jour), plusieurs côte à côte sur un
/// écran plus large. Le bandeau du haut mène à n'importe quel jour du séjour.
///
/// Deux affichages : la grille des heures (`CalendarTimeGrid`, par défaut),
/// comme Google Agenda, ou la liste de ce qui a lieu chaque jour.
///
/// La direction y ajoute des événements et agit sur chacun ; un animateur
/// lit et propose (cf. `ACCES.md`, « Calendrier du séjour »). Les jours
/// annulés d'une série ne se voient, barrés, que de la direction.
class CalendarDaysPage extends ConsumerStatefulWidget {
  final StayDto stay;
  final bool direction;

  const CalendarDaysPage({
    super.key,
    required this.stay,
    required this.direction,
  });

  @override
  ConsumerState<CalendarDaysPage> createState() => _CalendarDaysPageState();
}

class _CalendarDaysPageState extends ConsumerState<CalendarDaysPage>
    with AutomaticKeepAliveClientMixin {
  /// La largeur d'un jour en liste ; en grille, plus étroite.
  static const _listColumnWidth = 280.0;
  static const _gridColumnWidth = 140.0;
  static const _stripItemWidth = 56.0;

  /// En grille, un jour à la fois sous cette largeur (un téléphone).
  static const _gridCompactWidth = 600.0;

  final _strip = ScrollController();

  /// La grille s'ouvre sur 7 h, comme une journée commence (son heure
  /// lisible en haut).
  final _hours = ScrollController(initialScrollOffset: 7 * gridHourHeight - 16);
  bool _grid = true;
  late final List<DateTime> _days;
  late int _first;
  int _columns = 1;

  @override
  void initState() {
    super.initState();
    final stay = widget.stay;
    _days = [
      for (
        var day = stay.startsOn;
        !day.isAfter(stay.endsOn);
        day = DateTime.utc(day.year, day.month, day.day + 1)
      )
        day,
    ];
    _first = _todayIndex ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealStrip());
  }

  @override
  void dispose() {
    _strip.dispose();
    _hours.dispose();
    super.dispose();
  }

  /// Le jour affiché survit au passage par l'onglet des suggestions.
  @override
  bool get wantKeepAlive => true;

  static int _within(int value, int low, int high) =>
      math.max(low, math.min(high, value));

  int? get _todayIndex {
    final index = _days.indexOf(calendarDay(DateTime.now()));
    return index < 0 ? null : index;
  }

  void _show(int index) {
    final last = math.max(0, _days.length - _columns);
    setState(() => _first = _within(index, 0, last));
    _revealStrip();
  }

  /// Fait défiler le bandeau jusqu'au premier jour affiché.
  void _revealStrip() {
    if (!_strip.hasClients) return;
    final target = (_first * _stripItemWidth - _stripItemWidth)
        .clamp(0.0, _strip.position.maxScrollExtent)
        .toDouble();
    _strip.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Ajoute (ou propose) un événement, le jour affiché ou [day], de [start]
  /// à [end] s'il vient d'un créneau choisi dans la grille.
  Future<void> _add({DateTime? day, ClockTime? start, ClockTime? end}) async {
    final stay = widget.stay;
    final direction = widget.direction;
    final calendar = ref.read(stayCalendarControllerProvider(stay.id).notifier);
    final suggestions = ref.read(
      calendarSuggestionsControllerProvider(stay.id).notifier,
    );
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryEditorPage(
          stay: stay,
          title: direction ? 'Nouvel événement' : 'Proposer un événement',
          submitLabel: direction ? 'Ajouter' : 'Envoyer',
          intro: direction
              ? null
              : 'La direction verra votre proposition et pourra l\'accepter.',
          defaultDay: day ?? _days[_first],
          defaultStartTime: start,
          defaultEndTime: end,
          asksMessage: !direction,
          onSubmit: ({entry, occurrence, required message}) => direction
              ? calendar.create(entry!)
              : suggestions.add(entry!, message: message),
        ),
      ),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              direction
                  ? 'Événement ajouté.'
                  : 'Proposition envoyée à la direction.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stay = widget.stay;
    final calendar = ref.watch(stayCalendarControllerProvider(stay.id));
    final today = _todayIndex;

    return Scaffold(
      floatingActionButton: calendar.value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('addEntryButton'),
              onPressed: _add,
              icon: Icon(
                widget.direction ? Icons.add : Icons.lightbulb_outline,
              ),
              label: Text(widget.direction ? 'Ajouter' : 'Proposer'),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = _within(
            _grid
                ? (width < _gridCompactWidth
                      ? 1
                      : ((width - gridGutterWidth) / _gridColumnWidth).floor())
                : (width / _listColumnWidth).floor(),
            1,
            math.min(7, _days.length),
          );
          if (columns != _columns) {
            // Une autre largeur : le bandeau retrouve le premier jour affiché.
            _columns = columns;
            WidgetsBinding.instance.addPostFrameCallback((_) => _revealStrip());
          }
          final first = _within(
            _first,
            0,
            math.max(0, _days.length - _columns),
          );
          final visible = _days.sublist(first, first + _columns);

          return Column(
            children: [
              _DayStrip(
                days: _days,
                first: first,
                columns: _columns,
                today: today,
                controller: _strip,
                itemWidth: _stripItemWidth,
                onSelect: _show,
                onPrevious: first > 0 ? () => _show(first - _columns) : null,
                onNext: first + _columns < _days.length
                    ? () => _show(first + _columns)
                    : null,
                onToday: today == null ? null : () => _show(today),
                grid: _grid,
                onToggleView: () => setState(() => _grid = !_grid),
              ),
              const Divider(height: 1),
              Expanded(
                child: switch ((calendar.value, calendar.error)) {
                  (final StayCalendarDto value, _) => GestureDetector(
                    // Sur téléphone, on glisse d'un jour à l'autre.
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 300) return;
                      _show(first + (velocity < 0 ? _columns : -_columns));
                    },
                    child: _grid
                        ? CalendarTimeGrid(
                            stay: stay,
                            days: visible,
                            calendar: value,
                            direction: widget.direction,
                            scroll: _hours,
                            onRefresh: () => ref.refresh(
                              stayCalendarControllerProvider(stay.id).future,
                            ),
                            onSlot: (day, start, end) =>
                                _add(day: day, start: start, end: end),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (index, day) in visible.indexed) ...[
                                if (index > 0) const VerticalDivider(width: 1),
                                Expanded(
                                  child: _DayColumn(
                                    key: Key('day-${day.toIso8601String()}'),
                                    stay: stay,
                                    day: day,
                                    isToday: day == calendarDay(DateTime.now()),
                                    occurrences: value.on(
                                      day,
                                      withCancelled: widget.direction,
                                    ),
                                    direction: widget.direction,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  (_, final Object error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            calendarErrorMessage(
                              error is CalendarException
                                  ? error.code
                                  : CalendarErrorCode.unknown,
                            ),
                            key: const Key('calendarError'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(
                              stayCalendarControllerProvider(stay.id),
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Le bandeau des jours du séjour : on y touche un jour pour l'afficher.
class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final int first;
  final int columns;
  final int? today;
  final ScrollController controller;
  final double itemWidth;
  final ValueChanged<int> onSelect;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final bool grid;
  final VoidCallback onToggleView;

  const _DayStrip({
    required this.days,
    required this.first,
    required this.columns,
    required this.today,
    required this.controller,
    required this.itemWidth,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.grid,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          IconButton(
            key: const Key('previousDays'),
            tooltip: columns == 1 ? 'Jour précédent' : 'Jours précédents',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemExtent: itemWidth,
              itemBuilder: (context, index) {
                final day = days[index];
                final shown = index >= first && index < first + columns;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 8,
                  ),
                  child: Material(
                    color: shown ? colors.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key('strip-${day.day}-${day.month}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelect(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            shortWeekday(day),
                            style: text.labelSmall?.copyWith(
                              color: shown
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: text.titleMedium?.copyWith(
                              fontWeight: index == today
                                  ? FontWeight.bold
                                  : null,
                              color: index == today
                                  ? colors.primary
                                  : shown
                                  ? colors.onPrimaryContainer
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            key: const Key('nextDays'),
            tooltip: columns == 1 ? 'Jour suivant' : 'Jours suivants',
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
          if (onToday != null)
            IconButton(
              key: const Key('todayButton'),
              tooltip: 'Aujourd\'hui',
              icon: const Icon(Icons.today_outlined),
              onPressed: onToday,
            ),
          IconButton(
            key: const Key('toggleView'),
            tooltip: grid ? 'Afficher en liste' : 'Afficher en grille',
            icon: Icon(
              grid ? Icons.view_agenda_outlined : Icons.calendar_view_week,
            ),
            onPressed: onToggleView,
          ),
        ],
      ),
    );
  }
}

/// Ce qui a lieu un jour, dans l'ordre : à la journée, puis par heure.
class _DayColumn extends ConsumerWidget {
  final StayDto stay;
  final DateTime day;
  final bool isToday;
  final List<CalendarOccurrenceDto> occurrences;
  final bool direction;

  const _DayColumn({
    super.key,
    required this.stay,
    required this.day,
    required this.isToday,
    required this.occurrences,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(stayCalendarControllerProvider(stay.id).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayNewsDay(day),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isToday)
                Text(
                  'Aujourd\'hui',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (occurrences.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Rien de prévu ce jour-là.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final occurrence in occurrences)
            _OccurrenceTile(
              occurrence: occurrence,
              day: day,
              onTap: () => showOccurrenceSheet(
                context,
                ref,
                stay: stay,
                occurrence: occurrence,
                direction: direction,
              ),
            ),
        ],
      ),
    );
  }
}

/// Une occurrence dans la colonne de son jour : ses heures, son titre, son
/// lieu, et la couleur de sa catégorie.
class _OccurrenceTile extends StatelessWidget {
  final CalendarOccurrenceDto occurrence;
  final DateTime day;
  final VoidCallback onTap;

  const _OccurrenceTile({
    required this.occurrence,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = categoryColors(theme.colorScheme, occurrence.category);
    final cancelled = occurrence.cancelled;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Opacity(
      opacity: cancelled ? 0.55 : 1,
      child: Card(
        key: Key('occurrence-${occurrence.entryId}'),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 8),
        color: occurrence.isAllDay || occurrence.spansSeveralDays
            ? colors.background
            : null,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: colors.accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          categoryIcon(occurrence.category),
                          size: 18,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                occurrence.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  decoration: cancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  displayHours(occurrence, day),
                                  if (occurrence.place.isNotEmpty)
                                    occurrence.place,
                                ].join(' · '),
                                style: muted,
                              ),
                              if (cancelled || occurrence.changed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    cancelled
                                        ? 'Annulé ce jour'
                                        : 'Modifié ce jour',
                                    style: muted?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (occurrence.recurring)
                          Tooltip(
                            message: 'Se répète',
                            child: Icon(
                              Icons.repeat,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
