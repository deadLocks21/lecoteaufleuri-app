/// Un compte, identifié par son numéro de mobile.
class User {
  final String id;
  final String phoneNumber;
  final String firstName;
  final String lastName;

  /// Admin de l'association. Sert à l'app pour afficher l'espace
  /// d'administration ; l'API, elle, ne s'y fie jamais et relit le compte.
  final bool isAdmin;

  User({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.isAdmin = false,
  }) : assert(id.isNotEmpty, 'id cannot be empty');

  User copyWith({
    String? phoneNumber,
    String? firstName,
    String? lastName,
    bool? isAdmin,
  }) => User(
    id: id,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    isAdmin: isAdmin ?? this.isAdmin,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.isAdmin == isAdmin;

  @override
  int get hashCode =>
      Object.hash(id, phoneNumber, firstName, lastName, isAdmin);
}
