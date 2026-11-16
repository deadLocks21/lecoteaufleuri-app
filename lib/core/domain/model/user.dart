/// Un compte, identifié par son numéro de mobile.
class User {
  final String id;
  final String phoneNumber;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
  }) : assert(id.isNotEmpty, 'id cannot be empty');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.firstName == firstName &&
          other.lastName == lastName;

  @override
  int get hashCode => Object.hash(id, phoneNumber, firstName, lastName);
}
