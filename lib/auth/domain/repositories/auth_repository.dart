import '../entities/user.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> signIn({
    required String email, 
    required String password,
    bool rememberMe = false,
  });
  
  Future<AuthSession> signUp({
    required String name,
    required String lastName,
    String? secondLastName,
    required String username,
    required int age,
    required String gender,
    required String job,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    required String role,
  });
  
  Future<void> signOut();
  Future<bool> refreshToken();
  Future<UserInfoEntity> getCurrentUser();
  Future<UserInfoEntity> updateProfile(UserInfoEntity user);
  Future<bool> isLoggedIn();
}