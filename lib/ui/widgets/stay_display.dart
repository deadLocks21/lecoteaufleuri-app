import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _dayOfMonth(DateTime day) => day.day == 1 ? '1er' : '${day.day}';

String _dayAndMonth(DateTime day) =>
    '${_dayOfMonth(day)} ${_months[day.month - 1]}';

/// Un jour tel qu'on l'écrit en France : `10 juillet 2027`, `1er août 2027`.
String displayDay(DateTime day) => '${_dayAndMonth(day)} ${day.year}';

/// Les dates d'un séjour, sans répéter le mois ni l'année communs :
/// `Le 10 juillet 2027`, `Du 10 au 24 juillet 2027`,
/// `Du 28 juin au 5 juillet 2027`, `Du 30 décembre 2026 au 3 janvier 2027`.
String displayStayDates(DateTime startsOn, DateTime endsOn) {
  if (startsOn.year == endsOn.year &&
      startsOn.month == endsOn.month &&
      startsOn.day == endsOn.day) {
    return 'Le ${displayDay(startsOn)}';
  }
  final start = startsOn.year != endsOn.year
      ? displayDay(startsOn)
      : startsOn.month != endsOn.month
      ? _dayAndMonth(startsOn)
      : _dayOfMonth(startsOn);
  return 'Du $start au ${displayDay(endsOn)}';
}

/// Libellé court de la nature d'un séjour.
String stayKindLabel(StayKind kind) => switch (kind) {
  StayKind.acm => 'ACM',
  StayKind.other => 'Hors ACM',
};

/// Libellé d'un rôle dans l'équipe d'un séjour.
String staffRoleLabel(StaffRole role) => switch (role) {
  StaffRole.director => 'Directeur',
  StaffRole.deputy => 'Adjoint',
  StaffRole.animator => 'Animateur',
};

/// Ce que la nature d'un séjour change, pour qui le crée.
String stayKindDescription(StayKind kind) => switch (kind) {
  StayKind.acm =>
    'Accueil collectif de mineurs : les enfants sont inscrits par leurs '
        'parents.',
  StayKind.other => 'Chaque participant est inscrit en son nom.',
};
