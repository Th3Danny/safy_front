import 'package:safy/auth/domain/entities/user.dart';

class UserDto {
  final String id;
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final String job;
  final bool verified;
  final bool isActive;

  const UserDto({
    required this.id,
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.email,
    required this.job,
    required this.phoneNumber,
    required this.role,
    required this.verified,
    required this.isActive,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      lastName: json['lastname'] ?? '',
      secondLastName: json['second_lastname'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? '',
      job: json['job'] ?? '',
      verified: json['verified'] ?? false,
      isActive: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastname': lastName,
    if (secondLastName != null) 'second_lastname': secondLastName,
    'username': username,
    'email': email,
    'phone_number': phoneNumber,
    'role': role,
    'job': job,
    'verified': verified,
    'active': isActive,
  };

  UserInfoEntity toDomainEntity() {
    return UserInfoEntity(
      id: id,
      name: name,
      lastName: lastName,
      secondLastName: secondLastName,
      username: username,
      email: email,
      job: job,
      phoneNumber: phoneNumber,
      role: role,
      verified: verified,
      isActive: isActive,
    );
  }
}
