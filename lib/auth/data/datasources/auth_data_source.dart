
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:safy/auth/data/dtos/user_dto.dart';
import '../dtos/auth_request_dto.dart';
import '../dtos/auth_response_dto.dart';
import '../dtos/refresh_token_dto.dart';
import '../../domain/exceptions/auth_exceptions.dart';

class AuthApiClient {
  final Dio _dio;
  
  // Base de datos simulada en memoria
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'name': 'Yazmin',
      'last_name': 'Reyes',
      'second_last_name': 'Ruiz',
      'username': 'yazmin_reyes',
      'email': 'yazmin@example.com',
      'password': '123456',
      'age': 22,
      'gender': 'female',
      'job_type': 'student',
      'profile_image_url': null,
      'is_active': true,
      'created_at': '2024-01-15T10:00:00Z',
    },
    {
      'id': '2',
      'name': 'Julián',
      'last_name': 'Gutiérrez',
      'second_last_name': 'López',
      'username': 'julian_gutierrez',
      'email': 'julian@example.com',
      'password': '123456',
      'age': 23,
      'gender': 'male',
      'job_type': 'student',
      'profile_image_url': null,
      'is_active': true,
      'created_at': '2024-01-15T10:00:00Z',
    },
    {
      'id': '3',
      'name': 'Gerson',
      'last_name': 'García',
      'second_last_name': 'Domínguez',
      'username': 'gerson_garcia',
      'email': 'gerson@example.com',
      'password': '123456',
      'age': 24,
      'gender': 'male',
      'job_type': 'employee',
      'profile_image_url': null,
      'is_active': true,
      'created_at': '2024-01-15T10:00:00Z',
    },
  ];

  AuthApiClient(this._dio);

  /// Simula el login con datos mock
  Future<AuthResponseDto> signIn(LoginRequestDto requestDto) async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 1500));

      // Buscar usuario por email
      final user = _mockUsers.firstWhere(
        (user) => user['email'] == requestDto.email,
        orElse: () => throw const InvalidCredentialsException('Usuario no encontrado'),
      );

      // Verificar contraseña
      final storedPassword = user['password'] as String?;
      if (storedPassword != requestDto.password) {
        throw const InvalidCredentialsException('Contraseña incorrecta');
      }

      // Verificar si la cuenta está activa
      final isActive = user['is_active'] as bool? ?? false;
      if (!isActive) {
        throw const AccountNotActiveException();
      }

      // ✅ Cast explícito a String para el ID
      final userId = user['id'] as String;
      
      // Generar tokens simulados
      final accessToken = _generateMockJWT(userId, 3600); // 1 hora
      final refreshToken = _generateMockJWT(userId, 86400 * 7); // 7 días

      // Simular respuesta exitosa
      final response = {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': 3600,
        'user': Map<String, dynamic>.from(user)..remove('password'),
      };

      return AuthResponseDto.fromJson(response);

    } on AuthException {
      rethrow;
    } catch (e) {
      print('[AuthApiClient] Error en signIn: $e');
      throw const InvalidCredentialsException('Error en el servidor');
    }
  }

  /// Simula el registro con validaciones
  Future<AuthResponseDto> signUp(RegisterRequestDto requestDto) async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 2000));

      // Validaciones
      await _validateRegistration(requestDto);

      // ✅ Generar ID como String directamente
      final newUserId = _generateId(); // Ya retorna String

      // Crear nuevo usuario
      final newUser = <String, dynamic>{
        'id': newUserId, // ✅ Directamente String
        'name': requestDto.name.trim(),
        'last_name': requestDto.lastName.trim(),
        'second_last_name': requestDto.secondLastName?.trim(),
        'username': requestDto.username.trim().toLowerCase(),
        'email': requestDto.email.trim().toLowerCase(),
        'password': requestDto.password,
        'age': requestDto.age,
        'gender': requestDto.gender,
        'job_type': requestDto.jobType,
        'profile_image_url': null,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Agregar a la "base de datos"
      _mockUsers.add(newUser);

      // ✅ Usar el ID ya como String
      final accessToken = _generateMockJWT(newUserId, 3600);
      final refreshToken = _generateMockJWT(newUserId, 86400 * 7);

      // Respuesta exitosa (remover password de la respuesta)
      final responseUser = Map<String, dynamic>.from(newUser);
      responseUser.remove('password');

      final response = {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': 3600,
        'user': responseUser,
      };

      return AuthResponseDto.fromJson(response);

    } on AuthException {
      rethrow;
    } catch (e) {
      print('[AuthApiClient] Error en signUp: $e');
      throw AuthException('Error durante el registro: ${e.toString()}');
    }
  }

  /// Simula refresh del token
  Future<RefreshTokenResponseDto> refreshToken(RefreshTokenRequestDto requestDto) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Simular validación del refresh token
      final userId = _extractUserIdFromToken(requestDto.refreshToken);
      if (userId == null || userId.isEmpty) {
        throw const InvalidTokenException('Refresh token inválido');
      }

      // Generar nuevos tokens
      final newAccessToken = _generateMockJWT(userId, 3600);
      final newRefreshToken = _generateMockJWT(userId, 86400 * 7);

      return RefreshTokenResponseDto.fromJson({
        'access_token': newAccessToken,
        'refresh_token': newRefreshToken,
        'expires_in': 3600,
      });

    } catch (e) {
      if (e is AuthException) rethrow;
      print('[AuthApiClient] Error en refreshToken: $e');
      throw const InvalidTokenException('Error al renovar el token');
    }
  }

  /// Simula obtener perfil del usuario
  Future<UserDto> getProfile(String token) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final userId = _extractUserIdFromToken(token);
      if (userId == null || userId.isEmpty) {
        throw const InvalidTokenException('Token inválido');
      }

      final user = _mockUsers.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => throw const UserNotFoundException(),
      );

      // Crear copia sin password
      final userResponse = Map<String, dynamic>.from(user);
      userResponse.remove('password');

      return UserDto.fromJson(userResponse);

    } catch (e) {
      if (e is AuthException) rethrow;
      print('[AuthApiClient] Error en getProfile: $e');
      throw const AuthException('Error al obtener el perfil');
    }
  }

  /// Simula logout
  Future<void> signOut(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('[AuthApiClient] Usuario deslogueado exitosamente');
  }

  // ===== MÉTODOS PRIVADOS PARA SIMULACIÓN =====

  Future<void> _validateRegistration(RegisterRequestDto request) async {
    final errors = <String, List<String>>{};

    // Validar email único
    final emailExists = _mockUsers.any((user) => 
        (user['email'] as String?) == request.email.trim().toLowerCase());
    if (emailExists) {
      errors['email'] = ['El correo electrónico ya está registrado'];
    }

    // Validar username único
    final usernameExists = _mockUsers.any((user) => 
        (user['username'] as String?) == request.username.trim().toLowerCase());
    if (usernameExists) {
      errors['username'] = ['El nombre de usuario ya está en uso'];
    }

    // Validar formato de email
    if (!_isValidEmail(request.email)) {
      errors['email'] = [...(errors['email'] ?? []), 'Formato de correo inválido'];
    }

    // Validar contraseñas coinciden
    if (request.password != request.confirmPassword) {
      errors['confirm_password'] = ['Las contraseñas no coinciden'];
    }

    // Validar fortaleza de contraseña
    if (request.password.length < 6) {
      errors['password'] = ['La contraseña debe tener al menos 6 caracteres'];
    }

    // Validar edad
    if (request.age < 13 || request.age > 120) {
      errors['age'] = ['La edad debe estar entre 13 y 120 años'];
    }

    // Validar campos requeridos
    if (request.name.trim().isEmpty) {
      errors['name'] = ['El nombre es requerido'];
    }
    if (request.lastName.trim().isEmpty) {
      errors['lastName'] = ['El apellido es requerido'];
    }
    if (request.username.trim().isEmpty) {
      errors['username'] = [...(errors['username'] ?? []), 'El nombre de usuario es requerido'];
    }

    if (errors.isNotEmpty) {
      throw ValidationException('Errores de validación', errors);
    }
  }

  String _generateMockJWT(String userId, int expiresInSeconds) {
    try {
      final header = base64Url.encode(utf8.encode(jsonEncode({
        'alg': 'HS256',
        'typ': 'JWT',
      })));

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = base64Url.encode(utf8.encode(jsonEncode({
        'sub': userId,
        'iat': now,
        'exp': now + expiresInSeconds,
        'iss': 'safy-app',
        'aud': 'safy-users',
      })));

      final signature = base64Url.encode(
        utf8.encode('mock-signature-${Random().nextInt(999999)}')
      );

      return '$header.$payload.$signature';
    } catch (e) {
      print('[AuthApiClient] Error generando JWT: $e');
      throw const AuthException('Error generando token');
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('[AuthApiClient] Token formato inválido');
        return null;
      }

      // Decodificar payload
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      
      final userId = payloadMap['sub'] as String?;
      print('[AuthApiClient] UserId extraído del token: $userId');
      return userId;
    } catch (e) {
      print('[AuthApiClient] Error extrayendo userId del token: $e');
      return null;
    }
  }

  /// ✅ Generar ID como String directamente
  String _generateId() {
    return (_mockUsers.length + 1).toString();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  /// Obtener usuario por ID (para uso interno)
  Map<String, dynamic>? _getUserById(String userId) {
    try {
      return _mockUsers.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return null;
    }
  }

  /// Debug: Mostrar usuarios registrados
  static void printMockUsers() {
    print('=== USUARIOS MOCK REGISTRADOS ===');
    for (final user in _mockUsers) {
      print('ID: ${user['id']}, Email: ${user['email']}, Username: ${user['username']}');
    }
    print('================================');
  }
}

// lib/features/auth/data/dtos/auth_request_dto.dart
// ✅ DTOs con validaciones mejoradas

class LoginRequestDto {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequestDto({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
    'remember_me': rememberMe,
  };

  @override
  String toString() => 'LoginRequestDto(email: $email, rememberMe: $rememberMe)';
}

class RegisterRequestDto {
  final String name;
  final String lastName;
  final String? secondLastName;
  final String username;
  final int age;
  final String gender;
  final String jobType;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterRequestDto({
    required this.name,
    required this.lastName,
    this.secondLastName,
    required this.username,
    required this.age,
    required this.gender,
    required this.jobType,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'last_name': lastName.trim(),
    if (secondLastName != null && secondLastName!.isNotEmpty) 
      'second_last_name': secondLastName!.trim(),
    'username': username.trim().toLowerCase(),
    'age': age,
    'gender': gender,
    'job_type': jobType,
    'email': email.trim().toLowerCase(),
    'password': password,
    'confirm_password': confirmPassword,
  };

  @override
  String toString() => 'RegisterRequestDto(name: $name $lastName, username: $username, email: $email)';
}

// Ejemplo de uso mejorado en los tests:
/*
void main() {
  // Ver usuarios registrados
  AuthApiClient.printMockUsers();
  
  // Probar login
  final loginRequest = LoginRequestDto(
    email: 'yazmin@example.com',
    password: '123456',
    rememberMe: true,
  );
  
  // Probar registro
  final registerRequest = RegisterRequestDto(
    name: 'Test',
    lastName: 'User',
    username: 'testuser',
    age: 25,
    gender: 'female',
    jobType: 'student',
    email: 'test@example.com',
    password: '123456',
    confirmPassword: '123456',
  );
}
*/