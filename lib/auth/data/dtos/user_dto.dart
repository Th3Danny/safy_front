import 'package:safy/auth/domain/entities/user.dart';

class UserDto {
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

  const UserDto({
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? '',
      secondLastName: json['second_last_name'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      jobType: json['job_type'] ?? '',
      profileImageUrl: json['profile_image_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'last_name': lastName,
    if (secondLastName != null) 'second_last_name': secondLastName,
    'username': username,
    'email': email,
    'age': age,
    'gender': gender,
    'job_type': jobType,
    if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  // 🎯 Método directo para convertir UserDto a UserInfoEntity
  UserInfoEntity toDomainEntity() {
    return UserInfoEntity(
      id: id,
      name: name,
      lastName: lastName,
      secondLastName: secondLastName,
      username: username,
      email: email,
      age: age,
      gender: gender,
      jobType: jobType,
      profileImageUrl: profileImageUrl,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}