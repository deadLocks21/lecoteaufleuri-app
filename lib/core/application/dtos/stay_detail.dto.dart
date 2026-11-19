import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

/// Un membre de la direction, tel que l'UI l'affiche.
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

/// Un séjour et sa direction, avec ce que le compte connecté peut y changer.
class StayDetailDto {
  final StayDto stay;
  final List<TeamMemberDto> directors;
  final List<TeamMemberDto> deputies;
  final bool canManageDirectors;
  final bool canManageDeputies;

  const StayDetailDto({
    required this.stay,
    required this.directors,
    required this.deputies,
    required this.canManageDirectors,
    required this.canManageDeputies,
  });

  factory StayDetailDto.fromDomain(StayDetail detail) => StayDetailDto(
    stay: StayDto.fromDomain(detail.stay),
    directors: detail.directors.map(TeamMemberDto.fromDomain).toList(),
    deputies: detail.deputies.map(TeamMemberDto.fromDomain).toList(),
    canManageDirectors: detail.canManageDirectors,
    canManageDeputies: detail.canManageDeputies,
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
