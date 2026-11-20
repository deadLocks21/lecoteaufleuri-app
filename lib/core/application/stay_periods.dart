import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';

/// Où en est un séjour par rapport à aujourd'hui.
enum StayPeriod { current, upcoming, past }

/// La période de [stay] le jour [today] (un jour à minuit UTC, cf.
/// `calendarDay`) : en cours du premier au dernier jour compris.
StayPeriod stayPeriod(StayDto stay, DateTime today) {
  if (today.isBefore(stay.startsOn)) return StayPeriod.upcoming;
  if (today.isAfter(stay.endsOn)) return StayPeriod.past;
  return StayPeriod.current;
}

/// [stays] rangés par période, chacune dans l'ordre où on y cherche son
/// séjour : en cours, celui qui finit le plus tôt d'abord ; à venir, le plus
/// proche d'abord ; passés, le plus récent d'abord. Toutes les périodes sont
/// présentes, vides au besoin.
Map<StayPeriod, List<MyStayDto>> staysByPeriod(
  List<MyStayDto> stays,
  DateTime today,
) {
  final grouped = {
    for (final period in StayPeriod.values) period: <MyStayDto>[],
  };
  for (final mine in stays) {
    grouped[stayPeriod(mine.stay, today)]!.add(mine);
  }
  int byStart(MyStayDto a, MyStayDto b) =>
      a.stay.startsOn.compareTo(b.stay.startsOn);
  int byEnd(MyStayDto a, MyStayDto b) => a.stay.endsOn.compareTo(b.stay.endsOn);
  grouped[StayPeriod.current]!.sort(byEnd);
  grouped[StayPeriod.upcoming]!.sort(byStart);
  grouped[StayPeriod.past]!.sort((a, b) => byEnd(b, a));
  return grouped;
}

/// Le séjour où ouvrir l'app : le dernier ouvert s'il n'est pas terminé, sinon
/// celui en cours, sinon le prochain, sinon le dernier passé ; `null` sans
/// aucun séjour.
MyStayDto? defaultStay(
  List<MyStayDto> stays, {
  String? lastOpenedId,
  required DateTime today,
}) {
  final last = stays.where((mine) => mine.stay.id == lastOpenedId).firstOrNull;
  if (last != null && stayPeriod(last.stay, today) != StayPeriod.past) {
    return last;
  }
  final byPeriod = staysByPeriod(stays, today);
  return byPeriod[StayPeriod.current]!.firstOrNull ??
      byPeriod[StayPeriod.upcoming]!.firstOrNull ??
      byPeriod[StayPeriod.past]!.firstOrNull;
}
