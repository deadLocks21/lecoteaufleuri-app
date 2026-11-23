import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/day_layout.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';

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
/// Toucher un créneau libre y ajoute un événement (la direction) ou en
/// propose un (un animateur), à cette heure-là.
class CalendarTimeGrid extends ConsumerWidget {
  final StayDto stay;
  final List<DateTime> days;
  final StayCalendarDto calendar;
  final bool direction;
  final ScrollController scroll;
  final Future<void> Function() onRefresh;
  final void Function(DateTime day, ClockTime start) onSlot;

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
                          onSlot: (start) => onSlot(day, start),
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
            Text(
              shortWeekday(day),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isToday ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Container(
                width: 34,
                height: 34,
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
class _DayHours extends StatelessWidget {
  final DateTime day;
  final List<PlacedOccurrence> placed;
  final bool isToday;
  final ValueChanged<CalendarOccurrenceDto> onOpen;
  final ValueChanged<ClockTime> onSlot;

  const _DayHours({
    required this.day,
    required this.placed,
    required this.isToday,
    required this.onOpen,
    required this.onSlot,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: Key('slots-${day.toIso8601String()}'),
                behavior: HitTestBehavior.opaque,
                // Le créneau de la demi-heure touchée.
                onTapUp: (details) {
                  final minutes =
                      (details.localPosition.dy / gridHourHeight * 60) ~/
                      30 *
                      30;
                  final start = minutes.clamp(0, minutesPerDay - 30);
                  onSlot(ClockTime(start ~/ 60, start % 60));
                },
                child: CustomPaint(
                  painter: _HourLines(
                    hour: colors.outlineVariant,
                    halfHour: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            for (final item in placed)
              Positioned(
                top: item.start / 60 * gridHourHeight,
                height: (item.end - item.start) / 60 * gridHourHeight,
                left: 2 + item.lane * (width - 4) / item.lanes,
                width: (width - 4) / item.lanes,
                child: _Block(
                  placed: item,
                  day: day,
                  onTap: () => onOpen(item.occurrence),
                ),
              ),
            if (isToday) const _NowLine(),
          ],
        );
      },
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
          borderRadius: BorderRadius.circular(6),
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
