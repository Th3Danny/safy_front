import 'dart:convert';
import 'package:safy/auth/domain/entities/auth_session.dart';
import 'package:safy/auth/domain/entities/user.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();

  AuthSession? _currentSession;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStoredSession();
  }

  AuthSession? get currentSession => _currentSession;
  UserInfoEntity? get currentUser => _currentSession?.user;
  bool get isLoggedIn => _currentSession != null && !_currentSession!.isExpired;
  bool get isTokenExpiringSoon => _currentSession?.isExpiringSoon ?? false;
  String? get accessToken => _currentSession?.accessToken;
  String? get refreshToken => _currentSession?.refreshToken;

  ///  Crear sesión con UserInfoEntity
  Future<void> createSession({
    required UserInfoEntity user,  
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    bool rememberMe = false,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    
    _currentSession = AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      rememberMe: rememberMe,
    );

    await _saveSessionToStorage();
    print('[SessionManager] Sesión creada para usuario: ${user.username}');
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para actualizar');
    }

    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    
    _currentSession = _currentSession!.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    await _saveSessionToStorage();
    print('[SessionManager] Tokens actualizados');
  }

  ///  Actualizar usuario con UserInfoEntity
  Future<void> updateUser(UserInfoEntity user) async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para actualizar');
    }

    _currentSession = _currentSession!.copyWith(user: user);
    await _saveSessionToStorage();
    print('[SessionManager] Usuario actualizado: ${user.username}');
  }

  Future<void> clearSession() async {
    _currentSession = null;
    await _clearStorageData();
    print('[SessionManager] Sesión cerrada y datos limpiados');
  }

  bool isTokenExpired() {
    if (_currentSession == null) return true;
    return _currentSession!.isExpired;
  }

  Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('[SessionManager] Error al decodificar token: $e');
      return null;
    }
  }

  Duration? getTimeUntilExpiration() {
    if (_currentSession == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(_currentSession!.expiresAt)) return Duration.zero;
    
    return _currentSession!.expiresAt.difference(now);
  }

  // ===== MÉTODOS PRIVADOS =====

  Future<void> _loadStoredSession() async {
    try {
      final accessToken = _prefs?.getString(ApiConstants.accessTokenKey);
      final refreshToken = _prefs?.getString(ApiConstants.refreshTokenKey);
      final userDataString = _prefs?.getString(ApiConstants.userDataKey);

      if (accessToken == null || refreshToken == null || userDataString == null) {
        print('[SessionManager] No hay sesión almacenada');
        return;
      }

      final userMap = jsonDecode(userDataString) as Map<String, dynamic>;
      
      // Crear UserInfoEntity desde los datos almacenados
      final user = UserInfoEntity(
        id: userMap['id'] ?? '',
        name: userMap['name'] ?? '',
        lastName: userMap['last_name'] ?? '',
        secondLastName: userMap['second_last_name'],
        username: userMap['username'] ?? '',
        email: userMap['email'] ?? '',
        age: userMap['age'] ?? 0,
        gender: userMap['gender'] ?? '',
        jobType: userMap['job_type'] ?? '',
        profileImageUrl: userMap['profile_image_url'],
        isActive: userMap['is_active'] ?? true,
        createdAt: DateTime.tryParse(userMap['created_at'] ?? '') ?? DateTime.now(),
      );

      final tokenPayload = getTokenPayload(accessToken);
      final exp = tokenPayload?['exp'] as int?;
      final expiresAt = exp != null 
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : DateTime.now().add(const Duration(hours: 1));

      _currentSession = AuthSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        rememberMe: true,
      );

      if (_currentSession!.isExpired) {
        print('[SessionManager] Sesión expirada, limpiando...');
        await clearSession();
      } else {
        print('[SessionManager] Sesión cargada para: ${user.username}');
      }

    } catch (e) {
      print('[SessionManager] Error cargando sesión: $e');
      await _clearStorageData();
    }
  }

  Future<void> _saveSessionToStorage() async {
    if (_currentSession == null || _prefs == null) return;

    try {
      if (_currentSession!.rememberMe) {
        await _prefs!.setString(ApiConstants.accessTokenKey, _currentSession!.accessToken);
        await _prefs!.setString(ApiConstants.refreshTokenKey, _currentSession!.refreshToken);
        
        // ✅ Convertir UserInfoEntity a Map para almacenamiento
        final userMap = {
          'id': _currentSession!.user.id,
          'name': _currentSession!.user.name,
          'last_name': _currentSession!.user.lastName,
          'second_last_name': _currentSession!.user.secondLastName,
          'username': _currentSession!.user.username,
          'email': _currentSession!.user.email,
          'age': _currentSession!.user.age,
          'gender': _currentSession!.user.gender,
          'job_type': _currentSession!.user.jobType,
          'profile_image_url': _currentSession!.user.profileImageUrl,
          'is_active': _currentSession!.user.isActive,
          'created_at': _currentSession!.user.createdAt.toIso8601String(),
        };
        
        await _prefs!.setString(ApiConstants.userDataKey, jsonEncode(userMap));
        print('[SessionManager] Sesión guardada en almacenamiento');
      }
    } catch (e) {
      print('[SessionManager] Error guardando sesión: $e');
    }
  }

  Future<void> _clearStorageData() async {
    if (_prefs == null) return;

    try {
      await Future.wait([
        _prefs!.remove(ApiConstants.accessTokenKey),
        _prefs!.remove(ApiConstants.refreshTokenKey),
        _prefs!.remove(ApiConstants.userDataKey),
      ]);
      print('[SessionManager] Datos de almacenamiento limpiados');
    } catch (e) {
      print('[SessionManager] Error limpiando almacenamiento: $e');
    }
  }
}