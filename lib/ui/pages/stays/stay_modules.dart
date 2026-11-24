import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

/// Les modules d'un séjour : un par sujet (nouvelles, calendrier, équipe, questions…), chacun avec
/// ses pages. Les tuiles de la vue d'ensemble, le menu latéral et le rail les
/// lisent tous ici.
///
/// Ils se suivent par ordre alphabétique, partout où on les liste.
///
/// Un module n'apparaît qu'à qui y a droit ([isOpenTo]) ; c'est un choix
/// d'écran, l'API refuse de toute façon le reste (cf. `ACCES.md`).
enum StayModule {
  calendar(
    path: 'calendrier',
    label: 'Calendrier',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  team(
    path: 'equipe',
    label: 'Équipe',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
  ),
  news(
    path: 'nouvelles',
    label: 'Nouvelles',
    icon: Icons.newspaper_outlined,
    selectedIcon: Icons.newspaper,
  ),
  questions(
    path: 'questions',
    label: 'Questions',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
  );

  /// Le segment d'URL du module, sous `/sejours/:id/`.
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const StayModule({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Ce que [space] permet d'y voir, pour un compte admin ou non.
  bool isOpenTo(StaySpaceDto space, {required bool isAdmin}) => switch (this) {
    // Toute l'équipe lit les nouvelles et y dépose des photos.
    StayModule.news => true,
    // Toute l'équipe lit le calendrier et y propose des changements.
    StayModule.calendar => true,
    // Toute l'équipe pose des questions et lit celles qui sont publiques.
    StayModule.questions => true,
    // L'équipe n'existe que sur un séjour ACM, et seule la direction la voit.
    StayModule.team =>
      space.stay.kind == StayKind.acm && isDirection(space, isAdmin: isAdmin),
  };

  /// Ce qu'on fait dans le module, sous son titre.
  String summary(StaySpaceDto space, {required bool isAdmin}) => switch (this) {
    StayModule.news =>
      isDirection(space, isAdmin: isAdmin)
          ? 'Les photos de l\'équipe, les journées, ce que voient les familles'
          : 'Vos photos et les nouvelles publiées',
    StayModule.calendar =>
      isDirection(space, isAdmin: isAdmin)
          ? 'La vie du séjour au jour le jour, les suggestions de l\'équipe'
          : 'Le programme du séjour, vos suggestions',
    StayModule.team => 'Directeurs, adjoints et animateurs',
    StayModule.questions =>
      isDirection(space, isAdmin: isAdmin)
          ? 'Vos questions, privées ou partagées, et celles de l\'équipe'
          : 'Les questions partagées, les vôtres à la direction',
  };

  /// Les modules de [space] qu'on montre au compte, dans l'ordre.
  static List<StayModule> openTo(StaySpaceDto space, {required bool isAdmin}) =>
      [
        for (final module in values)
          if (module.isOpenTo(space, isAdmin: isAdmin)) module,
      ];
}

/// L'admin, un directeur ou un adjoint : ceux qui composent les nouvelles et
/// voient l'équipe.
bool isDirection(StaySpaceDto space, {required bool isAdmin}) =>
    isAdmin ||
    space.role == StaffRole.director ||
    space.role == StaffRole.deputy;
