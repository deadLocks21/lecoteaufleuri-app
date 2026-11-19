import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';

/// Le rôle d'un compte dans l'équipe d'un séjour (cf. `ACCES.md` du dépôt
/// lecoteaufleuri/dev).
enum StaffRole {
  /// Dirige le séjour ; un séjour peut en avoir plusieurs, tous égaux.
  director,

  /// Seconde le directeur, avec ses droits sauf nommer ou retirer un adjoint.
  deputy,

  /// Encadre les participants ; n'a pas la main sur l'équipe.
  animator,
}

/// Un membre de l'équipe d'un séjour : son nom, pas son numéro.
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

/// Un séjour et son équipe, avec ce que le compte connecté peut y changer.
///
/// [canManageDirectors], [canManageDeputies] et [canManageAnimators] viennent
/// de l'API, qui revérifie à chaque action : l'app s'en sert pour adapter
/// l'écran, jamais pour protéger quoi que ce soit.
class StayDetail {
  final Stay stay;
  final List<TeamMember> directors;
  final List<TeamMember> deputies;
  final List<TeamMember> animators;
  final bool canManageDirectors;
  final bool canManageDeputies;
  final bool canManageAnimators;

  StayDetail({
    required this.stay,
    required List<TeamMember> directors,
    required List<TeamMember> deputies,
    required List<TeamMember> animators,
    required this.canManageDirectors,
    required this.canManageDeputies,
    required this.canManageAnimators,
  }) : directors = List.unmodifiable(directors),
       deputies = List.unmodifiable(deputies),
       animators = List.unmodifiable(animators);
}

/// Le prénom et le nom du compte à créer pour un numéro qui n'en a pas, au
/// moment où on nomme la personne (cf. `ACCES.md`).
class NewStaffAccount {
  final String firstName;
  final String lastName;

  const NewStaffAccount._(this.firstName, this.lastName);

  /// Lève `StayException(invalidPersonName)` si l'un des deux est vide.
  factory NewStaffAccount.parse({
    required String firstName,
    required String lastName,
  }) {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty || last.isEmpty) {
      throw const StayException(StayErrorCode.invalidPersonName);
    }
    return NewStaffAccount._(first, last);
  }
}

/// Un séjour où le compte connecté a un rôle.
class MyStay {
  final Stay stay;
  final StaffRole role;

  const MyStay({required this.stay, required this.role});
}
