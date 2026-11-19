import 'package:lecoteaufleuri/core/domain/model/stay.dart';

/// Le rôle d'un compte dans l'équipe d'un séjour (cf. `ACCES.md` du dépôt
/// lecoteaufleuri/dev).
enum StaffRole {
  /// Dirige le séjour ; un seul par séjour.
  director,

  /// Seconde le directeur, avec ses droits sauf nommer ou retirer un adjoint.
  deputy,
}

/// Un membre de la direction d'un séjour : son nom, pas son numéro.
class TeamMember {
  final String id;
  final String firstName;
  final String lastName;

  TeamMember({
    required this.id,
    required this.firstName,
    required this.lastName,
  }) : assert(id.isNotEmpty, 'id cannot be empty');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          other.id == id &&
          other.firstName == firstName &&
          other.lastName == lastName;

  @override
  int get hashCode => Object.hash(id, firstName, lastName);
}

/// Un séjour et sa direction, avec ce que le compte connecté peut y changer.
///
/// [canManageDirector] et [canManageDeputies] viennent de l'API, qui revérifie
/// à chaque action : l'app s'en sert pour adapter l'écran, jamais pour
/// protéger quoi que ce soit.
class StayDetail {
  final Stay stay;
  final TeamMember? director;
  final List<TeamMember> deputies;
  final bool canManageDirector;
  final bool canManageDeputies;

  StayDetail({
    required this.stay,
    required this.director,
    required List<TeamMember> deputies,
    required this.canManageDirector,
    required this.canManageDeputies,
  }) : deputies = List.unmodifiable(deputies);
}

/// Un séjour où le compte connecté a un rôle.
class MyStay {
  final Stay stay;
  final StaffRole role;

  const MyStay({required this.stay, required this.role});
}
