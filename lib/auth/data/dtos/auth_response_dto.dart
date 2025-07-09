import 'package:safy/auth/data/dtos/user_dto.dart';
import 'package:safy/auth/domain/entities/user.dart';

class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserDto user;

  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return AuthResponseDto(
      accessToken: data['access_token'] ?? '',
      refreshToken: data['refresh_token'] ?? '',
      tokenType: data['token_type'] ?? '',
      expiresIn: data['expires_in'] ?? 3600,
      user: UserDto.fromJson(data['user'] ?? {}),
    );
  }

  UserInfoEntity toDomainEntity() {
    return user.toDomainEntity();
  }
}
