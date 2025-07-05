class UserInfoEntity {
  final String id;
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final String email;
  final int age;
  final String gender;
  final String jobType;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserInfoEntity({
    required this.id,
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.email,
    required this.age,
    required this.gender,
    required this.jobType,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName {
    final parts = [name, lastName, secondLastName]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  String get initials {
    return '${name.isNotEmpty ? name[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  UserInfoEntity copyWith({
    String? id,
    String? name,
    String? lastName,
    String? secondLastName,
    String? username,
    String? email,
    int? age,
    String? gender,
    String? jobType,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserInfoEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      username: username ?? this.username,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      jobType: jobType ?? this.jobType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserInfoEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserInfoEntity(id: $id, username: $username, email: $email, fullName: $fullName)';
  }
}
