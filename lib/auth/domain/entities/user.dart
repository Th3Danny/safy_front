class UserInfoEntity {
  final String id;
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String job;
  final String role;
  final bool verified;
  final bool isActive;

  const UserInfoEntity({
    required this.id,
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.job,
    required this.verified,
    required this.isActive,
  });

  String get fullName {
    final parts = [name, lastName, secondLastName]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  String get initials {
    return '${name.isNotEmpty ? name[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  @override
  String toString() {
    return 'UserInfoEntity(id: $id, username: $username, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is UserInfoEntity && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
