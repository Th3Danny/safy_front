import 'package:dio/dio.dart';
import 'package:safy/auth/data/datasources/auth_data_source.dart';
import 'package:safy/auth/data/dtos/auth_request_dto.dart';
import 'package:safy/auth/data/dtos/refresh_token_dto.dart';
import 'package:safy/auth/domain/entities/auth_session.dart';
import 'package:safy/auth/domain/entities/user.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/auth/domain/repositories/auth_repository.dart';
import 'package:safy/core/session/session_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiClient _apiClient;
  final SessionManager _sessionManager;

  AuthRepositoryImpl(this._apiClient, this._sessionManager);

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      //  SINTAXIS CORRECTA: new palabra clave opcional, pero es un constructor
      final requestDto = LoginRequestDto(
        email: email,
        password: password,
        //rememberMe: rememberMe,
      );

      final response = await _apiClient.signIn(requestDto);
      final user = response.toDomainEntity();

      await _sessionManager.createSession(
        user: user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        rememberMe: rememberMe,
      );

      return _sessionManager.currentSession!;
    } on DioException catch (e) {
      throw _mapDioErrorToAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error inesperado durante el login: ${e.toString()}');
    }
  }

  @override
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
    String? fcmToken,
  }) async {
    try {
      //  SINTAXIS CORRECTA: Constructor de RegisterRequestDto
      final requestDto = RegisterRequestDto(
        name: name,
        lastName: lastName,
        secondLastName: secondLastName,
        username: username,
        age: age,
        gender: gender,
        job: job,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        role: role, // Asignar rol por defecto
        fcmToken: fcmToken,
      );

      final response = await _apiClient.signUp(requestDto);
      final user = response.toDomainEntity();

      await _sessionManager.createSession(
        user: user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        rememberMe: true,
      );

      return _sessionManager.currentSession!;
    } on DioException catch (e) {
      throw _mapDioErrorToAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Error inesperado durante el registro: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final accessToken = _sessionManager.accessToken;
      if (accessToken != null) {
        await _apiClient.signOut(accessToken);
      }
    } catch (e) {
      // Removed debug print
    } finally {
      await _sessionManager.clearSession();
    }
  }

  @override
  Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = _sessionManager.refreshToken;
      if (refreshTokenValue == null) return false;

      final response = await _apiClient.refreshToken(
        RefreshTokenRequestDto(refreshToken: refreshTokenValue),
      );

      await _sessionManager.updateTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
      );

      return true;
    } catch (e) {
      await _sessionManager.clearSession();
      return false;
    }
  }

  @override
  Future<UserInfoEntity> getCurrentUser() async {
    final currentUser = _sessionManager.currentUser;
    if (currentUser == null) {
      throw const UserNotFoundException('No hay usuario logueado');
    }

    try {
      final accessToken = _sessionManager.accessToken!;
      final userDto = await _apiClient.getProfile(accessToken);
      final user = userDto.toDomainEntity();

      await _sessionManager.updateUser(user);
      return user;
    } catch (e) {
      return currentUser;
    }
  }

  @override
  Future<UserInfoEntity> updateProfile(UserInfoEntity user) async {
    try {
      await _sessionManager.updateUser(user);
      return user;
    } catch (e) {
      throw AuthException('Error actualizando perfil: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return _sessionManager.isLoggedIn;
  }

  AuthException _mapDioErrorToAuthException(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return const InvalidCredentialsException('Credenciales inválidas');
      case 401:
        return const InvalidCredentialsException(
          'Usuario o contraseña incorrectos',
        );
      case 403:
        return const AccountNotActiveException('Cuenta desactivada');
      case 404:
        return const UserNotFoundException('Usuario no encontrado');
      case 409:
        return const EmailAlreadyExistsException(
          'El correo ya está registrado',
        );
      case 422:
        final errors = e.response?.data?['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final fieldErrors = errors.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          );
          return ValidationException('Errores de validación', fieldErrors);
        }
        return const ValidationException('Datos inválidos', {});
      case 500:
        return const AuthException('Error interno del servidor');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const AuthException('Tiempo de conexión agotado');
        }
        if (e.type == DioExceptionType.connectionError) {
          return const AuthException(
            'Error de conexión. Verifica tu internet.',
          );
        }
        return AuthException('Error de red: ${e.message}');
    }
  }
}
