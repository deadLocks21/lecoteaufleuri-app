import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

/// Un membre de l'équipe, tel que l'UI l'affiche.
class TeamMemberDto {
  final String id;
  final String firstName;
  final String lastName;

  const TeamMemberDto({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory TeamMemberDto.fromDomain(TeamMember member) => TeamMemberDto(
    id: member.id,
    firstName: member.firstName,
    lastName: member.lastName,
  );

  String get fullName => '$firstName $lastName'.trim();
}

/// Un séjour et son équipe, avec ce que le compte connecté peut y changer.
class StayDetailDto {
  final StayDto stay;
  final List<TeamMemberDto> directors;
  final List<TeamMemberDto> deputies;
  final List<TeamMemberDto> animators;
  final bool canManageDirectors;
  final bool canManageDeputies;
  final bool canManageAnimators;

  const StayDetailDto({
    required this.stay,
    required this.directors,
    required this.deputies,
    required this.animators,
    required this.canManageDirectors,
    required this.canManageDeputies,
    required this.canManageAnimators,
  });

  factory StayDetailDto.fromDomain(StayDetail detail) => StayDetailDto(
    stay: StayDto.fromDomain(detail.stay),
    directors: detail.directors.map(TeamMemberDto.fromDomain).toList(),
    deputies: detail.deputies.map(TeamMemberDto.fromDomain).toList(),
    animators: detail.animators.map(TeamMemberDto.fromDomain).toList(),
    canManageDirectors: detail.canManageDirectors,
    canManageDeputies: detail.canManageDeputies,
    canManageAnimators: detail.canManageAnimators,
  );
}

/// Un séjour où le compte connecté a un rôle.
class MyStayDto {
  final StayDto stay;
  final StaffRole role;

  const MyStayDto({required this.stay, required this.role});

  factory MyStayDto.fromDomain(MyStay mine) =>
      MyStayDto(stay: StayDto.fromDomain(mine.stay), role: mine.role);
}

/// Un séjour tel que l'app l'ouvre pour le compte connecté : avec son rôle
/// dans l'équipe, ou [role] `null` pour un admin qui n'en fait pas partie.
class StaySpaceDto {
  final StayDto stay;
  final StaffRole? role;

  const StaySpaceDto({required this.stay, this.role});
}
