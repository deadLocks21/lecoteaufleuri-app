import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Le compte connecté, tel que l'UI l'affiche.
class UserDto {
  final String id;
  final String phoneNumber;
  final String firstName;
  final String lastName;

  const UserDto({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
  });

  factory UserDto.fromDomain(User user) => UserDto(
    id: user.id,
    phoneNumber: user.phoneNumber,
    firstName: user.firstName,
    lastName: user.lastName,
  );

  String get fullName => '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDto &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.firstName == firstName &&
          other.lastName == lastName;

  @override
  int get hashCode => Object.hash(id, phoneNumber, firstName, lastName);
}
