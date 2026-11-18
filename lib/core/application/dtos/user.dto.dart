import 'package:lecoteaufleuri/core/domain/model/user.dart';

/// Le compte connecté, tel que l'UI l'affiche.
class UserDto {
  final String id;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final bool isAdmin;

  const UserDto({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.isAdmin = false,
  });

  factory UserDto.fromDomain(User user) => UserDto(
    id: user.id,
    phoneNumber: user.phoneNumber,
    firstName: user.firstName,
    lastName: user.lastName,
    isAdmin: user.isAdmin,
  );

  String get fullName => '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDto &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.isAdmin == isAdmin;

  @override
  int get hashCode =>
      Object.hash(id, phoneNumber, firstName, lastName, isAdmin);
}
