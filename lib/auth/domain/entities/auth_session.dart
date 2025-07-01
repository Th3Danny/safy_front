import 'package:safy/auth/domain/entities/user.dart';

class AuthSession {
  final UserInfoEntity user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool rememberMe;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.rememberMe = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isExpiringSoon {
    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);
    return timeUntilExpiry.inMinutes < 15; 
  }

  AuthSession copyWith({
    UserInfoEntity? user,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool? rememberMe,
  }) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
} 