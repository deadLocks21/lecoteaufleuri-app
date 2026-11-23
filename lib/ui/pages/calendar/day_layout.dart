import 'dart:math' as math;

import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';

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
