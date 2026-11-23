import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/day_layout.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';

/// Le décalage d'une occurrence posée sur une autre, par cran.
const _nestIndent = 12.0;

/// La marge laissée libre à droite des blocs : on y clique ou glisse pour
/// ajouter un événement en parallèle.
const _freeMargin = 8.0;

/// La hauteur d'une heure dans la grille.
const gridHourHeight = 56.0;

/// La largeur de la colonne des heures, à gauche.
const gridGutterWidth = 52.0;

/// Le calendrier en grille, comme Google Agenda : les heures de la journée de
/// haut en bas, un jour par colonne. Chaque occurrence est un bloc posé à son
/// heure, aussi haut que sa durée ; celles qui se chevauchent se partagent la
/// largeur. Ce qui dure toute la journée (ou plusieurs jours) est dans le
/// bandeau du haut, sous le jour. Une ligne marque l'heure qu'il est.
///
/// Choisir un créneau libre — un clic, ou un glisser au quart d'heure près —
/// y ajoute un événement (la direction) ou en propose un (un animateur).
class CalendarTimeGrid extends ConsumerWidget {
  final StayDto stay;
  final List<DateTime> days;
  final StayCalendarDto calendar;
  final bool direction;
  final ScrollController scroll;
  final Future<void> Function() onRefresh;
  final void Function(DateTime day, ClockTime start, ClockTime end) onSlot;

  const CalendarTimeGrid({
    super.key,
    required this.stay,
    required this.days,
    required this.calendar,
    required this.direction,
    required this.scroll,
    required this.onRefresh,
    required this.onSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = calendarDay(DateTime.now());
    final byDay = {
      for (final day in days) day: calendar.on(day, withCancelled: direction),
    };
    void open(CalendarOccurrenceDto occurrence) => showOccurrenceSheet(
      context,
      ref,
      stay: stay,
      occurrence: occurrence,
      direction: direction,
    );

    return Column(
      children: [
        // Les jours, et ce qui y dure toute la journée.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: gridGutterWidth),
              for (final day in days)
                Expanded(
                  child: _DayHeader(
                    day: day,
                    isToday: day == today,
                    allDay: [
                      for (final occurrence in byDay[day]!)
                        if (!isTimedOn(occurrence, day)) occurrence,
                    ],
                    onOpen: open,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              key: const Key('timeGrid'),
              controller: scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 24 * gridHourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HourLabels(),
                    for (final day in days)
                      Expanded(
                        child: _DayHours(
                          day: day,
                          placed: layoutDay([
                            for (final occurrence in byDay[day]!)
                              if (isTimedOn(occurrence, day)) occurrence,
                          ]),
                          isToday: day == today,
                          onOpen: open,
                          onSlot: (start, end) => onSlot(day, start, end),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// L'en-tête d'un jour : `sam.` et `10` (cerclé aujourd'hui), puis ce qui
/// dure toute la journée.
class _DayHeader extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<CalendarOccurrenceDto> allDay;
  final ValueChanged<CalendarOccurrenceDto> onOpen;

  const _DayHeader({
    required this.day,
    required this.isToday,
    required this.allDay,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Column(
          key: Key('gridDay-${day.toIso8601String()}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Le jour et son numéro sur une ligne : « sam. 10 ».
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    shortWeekday(day),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isToday ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isToday ? colors.onPrimary : null,
                    ),
                  ),
                ),
              ],
            ),
            if (allDay.isNotEmpty) const SizedBox(height: 4),
            for (final occurrence in allDay)
              _AllDayChip(
                occurrence: occurrence,
                day: day,
                onTap: () => onOpen(occurrence),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  final CalendarOccurrenceDto occurrence;
  final DateTime day;
  final VoidCallback onTap;

  const _AllDayChip({
    required this.occurrence,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = categoryColors(theme.colorScheme, occurrence.category);
    final hours = displayHours(occurrence, day);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Opacity(
        opacity: occurrence.cancelled ? 0.5 : 1,
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('occurrence-${occurrence.entryId}'),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.accent, width: 3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                hours == 'Toute la journée'
                    ? occurrence.title
                    : '${occurrence.title} · $hours',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  decoration: occurrence.cancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les heures, dans la marge de gauche : `08:00`, alignées sur leur trait.
class _HourLabels extends StatelessWidget {
  const _HourLabels();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      width: gridGutterWidth,
      child: Stack(
        children: [
          for (var hour = 1; hour < 24; hour++)
            Positioned(
              top: hour * gridHourHeight - 7,
              right: 8,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

/// Les heures d'un jour : les traits des heures, les blocs des occurrences et,
/// aujourd'hui, la ligne de l'heure qu'il est.
///
/// On y choisit un créneau libre, au quart d'heure près : un clic (ou une
/// touche) pour une heure à partir du quart d'heure touché ; un glisser
/// pour en tracer la durée — à la souris directement, au doigt après un
/// appui long, pour ne pas confondre avec le défilement.
class _DayHours extends StatefulWidget {
  final DateTime day;
  final List<PlacedOccurrence> placed;
  final bool isToday;
  final ValueChanged<CalendarOccurrenceDto> onOpen;
  final void Function(ClockTime start, ClockTime end) onSlot;

  const _DayHours({
    required this.day,
    required this.placed,
    required this.isToday,
    required this.onOpen,
    required this.onSlot,
  });

  @override
  State<_DayHours> createState() => _DayHoursState();
}

class _DayHoursState extends State<_DayHours> {
  /// Le quart d'heure où le glisser a commencé, et celui où il en est.
  int? _anchor;
  int? _current;

  static int _quarterAt(double dy) => quarterAt(dy / gridHourHeight * 60);

  void _begin(double dy) => setState(() => _anchor = _current = _quarterAt(dy));

  void _extend(double dy) {
    if (_anchor == null) return;
    final quarter = _quarterAt(dy);
    if (quarter != _current) setState(() => _current = quarter);
  }

  void _finish() {
    final (anchor, current) = (_anchor, _current);
    _cancel();
    if (anchor == null || current == null) return;
    final slot = sweptSlot(anchor, current);
    widget.onSlot(clockAt(slot.start), clockAt(slot.end));
  }

  void _cancel() => setState(() => _anchor = _current = null);

  void _click(double dy) {
    final slot = clickedSlot(_quarterAt(dy));
    widget.onSlot(clockAt(slot.start), clockAt(slot.end));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selection = switch ((_anchor, _current)) {
      (final int anchor, final int current) => sweptSlot(anchor, current),
      _ => null,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: RawGestureDetector(
                key: Key('slots-${widget.day.toIso8601String()}'),
                behavior: HitTestBehavior.opaque,
                gestures: {
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(
                        TapGestureRecognizer.new,
                        (recognizer) =>
                            recognizer.onTapUp = (details) =>
                                _click(details.localPosition.dy),
                      ),
                  // À la souris, on glisse tout de suite : elle ne fait pas
                  // défiler la grille.
                  VerticalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        VerticalDragGestureRecognizer
                      >(
                        () => VerticalDragGestureRecognizer(
                          supportedDevices: const {PointerDeviceKind.mouse},
                        ),
                        (recognizer) => recognizer
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = ((details) {
                            _begin(details.localPosition.dy);
                          })
                          ..onUpdate = ((details) {
                            _extend(details.localPosition.dy);
                          })
                          ..onEnd = ((_) => _finish())
                          ..onCancel = _cancel,
                      ),
                  // Au doigt, le glisser fait défiler : on trace après un
                  // appui long.
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          supportedDevices: const {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        (recognizer) => recognizer
                          ..onLongPressStart = (details) {
                            HapticFeedback.selectionClick();
                            _begin(details.localPosition.dy);
                          }
                          ..onLongPressMoveUpdate = ((details) {
                            _extend(details.localPosition.dy);
                          })
                          ..onLongPressEnd = ((_) => _finish())
                          ..onLongPressCancel = _cancel,
                      ),
                },
                child: CustomPaint(
                  painter: _HourLines(
                    hour: colors.outlineVariant,
                    halfHour: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            for (final item in widget.placed)
              Positioned(
                top: item.start / 60 * gridHourHeight,
                height: (item.end - item.start) / 60 * gridHourHeight,
                left:
                    2 +
                    item.indent * _nestIndent +
                    item.lane *
                        (width - 4 - _freeMargin - item.indent * _nestIndent) /
                        item.lanes,
                width:
                    (width - 4 - _freeMargin - item.indent * _nestIndent) /
                    item.lanes,
                child: _Block(
                  placed: item,
                  day: widget.day,
                  onTap: () => widget.onOpen(item.occurrence),
                ),
              ),
            if (selection != null)
              Positioned(
                top: selection.start / 60 * gridHourHeight,
                height: (selection.end - selection.start) / 60 * gridHourHeight,
                left: 2,
                right: 2,
                child: _Selection(start: selection.start, end: selection.end),
              ),
            if (widget.isToday) const _NowLine(),
          ],
        );
      },
    );
  }
}

/// Le créneau qu'on trace, avec ses heures : `10:15 – 11:30`.
class _Selection extends StatelessWidget {
  final int start;
  final int end;

  const _Selection({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IgnorePointer(
      child: Container(
        key: const Key('slotSelection'),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.primary, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Text(
              '${clockAt(start).format()} – ${clockAt(end).format()}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un trait par heure, un plus discret à la demi-heure, et la séparation
/// avec le jour d'à côté.
class _HourLines extends CustomPainter {
  final Color hour;
  final Color halfHour;

  const _HourLines({required this.hour, required this.halfHour});

  @override
  void paint(Canvas canvas, Size size) {
    final strong = Paint()
      ..color = hour
      ..strokeWidth = 1;
    final light = Paint()
      ..color = halfHour
      ..strokeWidth = 1;
    for (var hour = 1; hour < 24; hour++) {
      final y = hour * gridHourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), strong);
      final half = y - gridHourHeight / 2;
      canvas.drawLine(Offset(0, half), Offset(size.width, half), light);
    }
    canvas.drawLine(Offset.zero, Offset(0, size.height), strong);
  }

  @override
  bool shouldRepaint(_HourLines old) =>
      old.hour != hour || old.halfHour != halfHour;
}

/// Une occurrence dans la grille : son titre, puis ses heures et son lieu
/// s'il y a la place.
class _Block extends StatelessWidget {
  final PlacedOccurrence placed;
  final DateTime day;
  final VoidCallback onTap;

  const _Block({required this.placed, required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrence = placed.occurrence;
    final colors = categoryColors(theme.colorScheme, occurrence.category);
    final cancelled = occurrence.cancelled;
    final compact = placed.end - placed.start < 30;
    final text = TextStyle(
      color: colors.foreground,
      decoration: cancelled ? TextDecoration.lineThrough : null,
    );
    final details = [
      displayHours(occurrence, day),
      if (occurrence.place.isNotEmpty) occurrence.place,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(right: 1, bottom: 1),
      child: Opacity(
        opacity: cancelled ? 0.5 : 1,
        child: Material(
          color: colors.background,
          // Un liseré de la couleur du fond : un bloc posé sur un autre s'en
          // détache.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: theme.colorScheme.surface),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('occurrence-${occurrence.entryId}'),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.accent, width: 3),
                ),
              ),
              padding: EdgeInsets.fromLTRB(5, compact ? 0 : 2, 4, 0),
              // Le texte s'arrête au bas du bloc, sans déborder.
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: compact
                      // Moins d'une demi-heure : tout sur une ligne.
                      ? Text(
                          '${occurrence.title} · ${displayHours(occurrence, day)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.merge(text)
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              occurrence.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium
                                  ?.merge(text)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              details,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.merge(text),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La ligne de l'heure qu'il est, redessinée chaque minute.
class _NowLine extends StatefulWidget {
  const _NowLine();

  @override
  State<_NowLine> createState() => _NowLineState();
}

class _NowLineState extends State<_NowLine> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final color = Theme.of(context).colorScheme.error;
    return Positioned(
      top: (now.hour * 60 + now.minute) / 60 * gridHourHeight - 5,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(child: Container(height: 2, color: color)),
          ],
        ),
      ),
    );
  }
}
