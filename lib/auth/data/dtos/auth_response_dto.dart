

import 'package:safy/auth/data/dtos/user_dto.dart';
import 'package:safy/auth/domain/entities/user.dart';

class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final UserDto user;
  final int expiresIn;

  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
      expiresIn: json['expires_in'] ?? 3600,
    );
  }

  // 🎯 MÉTODO CLAVE: Convertir DTO a Entidad de Dominio
  UserInfoEntity toDomainEntity() {
    return UserInfoEntity(
      id: user.id,
      name: user.name,
      lastName: user.lastName,
      secondLastName: user.secondLastName,
      username: user.username,
      email: user.email,
      age: user.age,
      gender: user.gender,
      jobType: user.jobType,
      profileImageUrl: user.profileImageUrl,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
  }
}