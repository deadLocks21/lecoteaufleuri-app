import 'dart:math' as math;

import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

/// Minutes dans une journée.
const minutesPerDay = 24 * 60;

/// Une occurrence placée dans les heures d'un jour : de [start] à [end]
/// (minutes depuis minuit, [end] allongée jusqu'à la durée minimale d'un
/// bloc), dans la voie [lane] sur [lanes] qui se partagent la largeur.
class PlacedOccurrence {
  final CalendarOccurrenceDto occurrence;
  final int start;
  final int end;
  final int lane;
  final int lanes;

  const PlacedOccurrence({
    required this.occurrence,
    required this.start,
    required this.end,
    required this.lane,
    required this.lanes,
  });
}

/// Ce qui se place dans les heures du jour [day] : une occurrence avec une
/// heure de début, ce jour-là, sur un seul jour. Le reste (à la journée, sur
/// plusieurs jours) va dans le bandeau du haut.
bool isTimedOn(CalendarOccurrenceDto occurrence, DateTime day) =>
    occurrence.startTime != null &&
    !occurrence.spansSeveralDays &&
    occurrence.startsOn == day;

/// Place les occurrences avec heure d'un jour, comme Google Agenda : chacune
/// à son heure, aussi haute que sa durée (au moins [minimumMinutes] : un
/// lever ou un coucher sans heure de fin tient un quart d'heure, sans
/// empiéter sur ce qui commence juste après), et celles qui se chevauchent
/// côte à côte, la largeur partagée entre elles.
List<PlacedOccurrence> layoutDay(
  Iterable<CalendarOccurrenceDto> occurrences, {
  int minimumMinutes = 15,
}) {
  final timed =
      [
        for (final occurrence in occurrences)
          if (occurrence.startTime case final start?)
            (
              occurrence: occurrence,
              start: start.minutes,
              end: math.min(
                minutesPerDay,
                math.max(
                  occurrence.endTime?.minutes ?? 0,
                  start.minutes + minimumMinutes,
                ),
              ),
            ),
      ]..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        // À même heure, la plus longue d'abord : elle prend la première voie.
        return byStart != 0 ? byStart : b.end.compareTo(a.end);
      });

  final placed = <PlacedOccurrence>[];
  // Un groupe : des occurrences qui se chevauchent de proche en proche.
  var group =
      <({CalendarOccurrenceDto occurrence, int start, int end, int lane})>[];
  final laneEnds = <int>[];
  var groupEnd = -1;

  void close() {
    for (final item in group) {
      placed.add(
        PlacedOccurrence(
          occurrence: item.occurrence,
          start: item.start,
          end: item.end,
          lane: item.lane,
          lanes: laneEnds.length,
        ),
      );
    }
    group = [];
    laneEnds.clear();
  }

  for (final item in timed) {
    if (group.isNotEmpty && item.start >= groupEnd) close();
    var lane = laneEnds.indexWhere((end) => end <= item.start);
    if (lane < 0) {
      lane = laneEnds.length;
      laneEnds.add(item.end);
    } else {
      laneEnds[lane] = item.end;
    }
    groupEnd = group.isEmpty ? item.end : math.max(groupEnd, item.end);
    group.add((
      occurrence: item.occurrence,
      start: item.start,
      end: item.end,
      lane: lane,
    ));
  }
  close();
  return placed;
}

/// La précision d'un créneau choisi dans la grille : le quart d'heure.
const slotMinutes = 15;

/// Le quart d'heure qui contient la minute [minutes] de la journée.
int quarterAt(double minutes) => (minutes ~/ slotMinutes * slotMinutes).clamp(
  0,
  minutesPerDay - slotMinutes,
);

/// Le créneau balayé d'un quart d'heure [from] à un autre [to], dans un sens
/// ou dans l'autre, tous deux compris : au moins un quart d'heure.
({int start, int end}) sweptSlot(int from, int to) =>
    (start: math.min(from, to), end: math.max(from, to) + slotMinutes);

/// Le créneau d'un simple clic : une heure à partir du quart d'heure touché,
/// sans passer minuit.
({int start, int end}) clickedSlot(int quarter) =>
    (start: quarter, end: math.min(quarter + 60, minutesPerDay));

/// L'heure de la minute [minutes] ; minuit, en fin de journée, s'écrit
/// `23:59` : un événement ne déborde pas sur le lendemain.
ClockTime clockAt(int minutes) => minutes >= minutesPerDay
    ? const ClockTime(23, 59)
    : ClockTime(minutes ~/ 60, minutes % 60);
