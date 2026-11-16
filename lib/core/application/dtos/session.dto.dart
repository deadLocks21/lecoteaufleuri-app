import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';

/// Vue UI d'une session : le compte et l'échéance, **sans le JWT**, qui ne
/// quitte jamais l'infrastructure (l'intercepteur HTTP le lit lui-même).
class SessionDto {
  final UserDto user;
  final DateTime expiresAt;

  const SessionDto({required this.user, required this.expiresAt});

  factory SessionDto.fromDomain(Session session) => SessionDto(
    user: UserDto.fromDomain(session.user),
    expiresAt: session.expiresAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDto && other.user == user && other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(user, expiresAt);
}
