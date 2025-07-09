import 'package:dio/dio.dart';
import 'package:safy/auth/data/dtos/auth_request_dto.dart';
import 'package:safy/auth/data/dtos/auth_response_dto.dart';
import 'package:safy/auth/data/dtos/refresh_token_dto.dart';
import 'package:safy/auth/data/dtos/user_dto.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';

class AuthApiClient {
  final Dio _dio;

  AuthApiClient(this._dio);

  /// 🔐 Login real contra API
  Future<AuthResponseDto> signIn(LoginRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: requestDto.toJson(),
      );

      return AuthResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// 🧾 Registro real contra API
  Future<AuthResponseDto> signUp(RegisterRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: requestDto.toJson(),
      );

      return AuthResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// 🔁 Refrescar token
  Future<RefreshTokenResponseDto> refreshToken(RefreshTokenRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: requestDto.toJson(),
      );

      return RefreshTokenResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// 👤 Obtener perfil del usuario autenticado
  Future<UserDto> getProfile(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.profile,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return UserDto.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// 🚪 Logout (si aplica en el backend)
  Future<void> signOut(String token) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ===== Manejo de errores centralizado =====
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      throw const InvalidCredentialsException('Credenciales inválidas');
    } else if (e.response?.statusCode == 409) {
      throw const AuthException('Conflicto: posible duplicado');
    } else if (e.response?.statusCode == 422) {
      throw ValidationException('Datos inválidos', e.response?.data['errors'] ?? {});
    } else if (e.response?.statusCode == 500) {
      throw const AuthException('Error del servidor');
    } else {
      throw AuthException('Error inesperado: ${e.message}');
    }
  }
}
