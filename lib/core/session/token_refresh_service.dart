import 'dart:async';
import 'package:safy/auth/data/datasources/auth_data_source.dart';
import 'package:safy/auth/data/dtos/refresh_token_dto.dart';

import 'session_manager.dart';

class TokenRefreshService {
  static TokenRefreshService? _instance;
  static TokenRefreshService get instance {
    if (_instance == null) {
      throw Exception('TokenRefreshService no ha sido inicializado. Llama a TokenRefreshService.initialize() primero.');
    }
    return _instance!;
  }

  final AuthApiClient _authApiClient;
  Timer? _refreshTimer;

  //  Constructor que recibe AuthApiClient
  TokenRefreshService._(this._authApiClient);

  /// Inicializar el servicio con el API client
  static void initialize(AuthApiClient authApiClient) {
    _instance = TokenRefreshService._(authApiClient);
  }

  /// Iniciar el monitoreo automático de refresh de tokens
  void startTokenRefreshMonitoring() {
    _refreshTimer?.cancel();
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndRefreshToken();
    });
    
    // Removed debug print
  }

  /// Detener el monitoreo
  void stopTokenRefreshMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    // Removed debug print
  }

  /// Forzar refresh del token
  Future<bool> forceRefreshToken() async {
    return await _refreshTokenIfNeeded(force: true);
  }

  Future<void> _checkAndRefreshToken() async {
    if (!SessionManager.instance.isLoggedIn) {
      stopTokenRefreshMonitoring();
      return;
    }

    if (SessionManager.instance.isTokenExpiringSoon) {
      await _refreshTokenIfNeeded();
    }
  }

  Future<bool> _refreshTokenIfNeeded({bool force = false}) async {
    try {
      final sessionManager = SessionManager.instance;
      
      if (!sessionManager.isLoggedIn) return false;
      
      if (!force && !sessionManager.isTokenExpiringSoon) return true;

      final refreshToken = sessionManager.refreshToken;
      if (refreshToken == null) return false;

      // Removed debug print
      
      final response = await _authApiClient.refreshToken(
        RefreshTokenRequestDto(refreshToken: refreshToken),
      );

      await sessionManager.updateTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
      );

      // Removed debug print
      return true;

    } catch (e) {
      // Removed debug print
      
      await SessionManager.instance.clearSession();
      stopTokenRefreshMonitoring();
      
      return false;
    }
  }
}
