import 'dart:math' as math;

import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

/// Minutes dans une journée.
const minutesPerDay = 24 * 60;

/// Une occurrence placée dans les heures d'un jour : de [start] à [end]
/// (minutes depuis minuit, [end] allongée jusqu'à la durée minimale d'un
/// bloc), dans la voie [lane] sur [lanes] qui se partagent la largeur, et
/// décalée de [indent] crans quand elle se pose sur une plus longue,
/// commencée avant elle.
class PlacedOccurrence {
  final CalendarOccurrenceDto occurrence;
  final int start;
  final int end;
  final int lane;
  final int lanes;
  final int indent;

  const PlacedOccurrence({
    required this.occurrence,
    required this.start,
    required this.end,
    required this.lane,
    required this.lanes,
    this.indent = 0,
  });
}

/// Ce qui se place dans les heures du jour [day] : une occurrence avec une
/// heure de début, ce jour-là, sur un seul jour. Le reste (à la journée, sur
/// plusieurs jours) va dans le bandeau du haut.
bool isTimedOn(CalendarOccurrenceDto occurrence, DateTime day) =>
    occurrence.startTime != null &&
    !occurrence.spansSeveralDays &&
    occurrence.startsOn == day;

/// En deçà de cet écart entre leurs débuts, deux occurrences qui se
/// chevauchent se mettent côte à côte : sinon, la seconde se poserait sur le
/// titre de la première.
const sideBySideMinutes = 30;

/// Au-delà de ces crans, une occurrence ne se décale plus : elle garderait
/// trop peu de largeur.
const maxIndent = 3;

/// Place les occurrences avec heure d'un jour, comme Google Agenda :
///
/// - chacune à son heure, aussi haute que sa durée (au moins
///   [minimumMinutes] : un lever ou un coucher sans heure de fin tient un
///   quart d'heure, sans empiéter sur ce qui commence juste après) ;
/// - celles qui commencent presque ensemble (moins de [sideBySideMinutes]
///   d'écart) et se chevauchent, côte à côte, la largeur partagée ;
/// - une qui commence plus tard, pendant une autre, se pose par-dessus,
///   décalée d'un cran ([PlacedOccurrence.indent]) : la plus longue garde
///   toute sa largeur, son titre et sa marge restent visibles.
///
/// Le résultat se dessine dans l'ordre : chaque occurrence par-dessus celles
/// sur lesquelles elle se pose.
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
  final count = timed.length;

  // Les groupes côte à côte : reliés de proche en proche par deux
  // occurrences qui se chevauchent en commençant presque ensemble.
  final parent = List<int>.generate(count, (i) => i);
  int root(int i) => parent[i] == i ? i : parent[i] = root(parent[i]);
  bool overlap(int earlier, int later) =>
      timed[later].start < timed[earlier].end;
  for (var later = 0; later < count; later++) {
    for (var earlier = 0; earlier < later; earlier++) {
      if (overlap(earlier, later) &&
          timed[later].start - timed[earlier].start < sideBySideMinutes) {
        parent[root(later)] = root(earlier);
      }
    }
  }
  final groups = <int, List<int>>{};
  for (var i = 0; i < count; i++) {
    groups.putIfAbsent(root(i), () => []).add(i);
  }

  // Dans l'ordre de leur début : un groupe se pose sur ceux, commencés
  // avant, qui durent encore quand l'un des siens commence.
  final depth = <int, int>{};
  final lanesOf = <int, ({int lane, int lanes})>{};
  for (final MapEntry(key: group, value: members) in groups.entries) {
    var level = 0;
    for (final member in members) {
      for (var earlier = 0; earlier < member; earlier++) {
        final other = depth[root(earlier)];
        if (other != null &&
            root(earlier) != group &&
            overlap(earlier, member)) {
          level = math.max(level, other + 1);
        }
      }
    }
    depth[group] = level;

    final laneEnds = <int>[];
    for (final member in members) {
      var lane = laneEnds.indexWhere((end) => end <= timed[member].start);
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(timed[member].end);
      } else {
        laneEnds[lane] = timed[member].end;
      }
      lanesOf[member] = (lane: lane, lanes: 0);
    }
    for (final member in members) {
      lanesOf[member] = (lane: lanesOf[member]!.lane, lanes: laneEnds.length);
    }
  }

  return [
    for (var i = 0; i < count; i++)
      PlacedOccurrence(
        occurrence: timed[i].occurrence,
        start: timed[i].start,
        end: timed[i].end,
        lane: lanesOf[i]!.lane,
        lanes: lanesOf[i]!.lanes,
        indent: math.min(maxIndent, depth[root(i)]!),
      ),
  ]..sort((a, b) {
    final byIndent = a.indent.compareTo(b.indent);
    return byIndent != 0 ? byIndent : a.start.compareTo(b.start);
  });
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
