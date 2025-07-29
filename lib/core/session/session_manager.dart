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
  bool _isInitialized = false;

  Future<void> initialize({SharedPreferences? prefs}) async {
    if (_isInitialized) {
      return;
    }

    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      // Removed debug print

      await _loadStoredSession();

      _isInitialized = true;
      // Removed debug print
      // Removed debug print
    } catch (e) {
      // Removed debug print
      _isInitialized = true; // Marcar como inicializado aún con error
    }
  }

  AuthSession? get currentSession => _currentSession;
  UserInfoEntity? get currentUser => _currentSession?.user;

  bool get isLoggedIn {
    final hasSession = _currentSession != null;
    final isNotExpired = hasSession ? !_currentSession!.isExpired : false;
    final result = hasSession && isNotExpired;

    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print

    return result;
  }

  bool get isTokenExpiringSoon => _currentSession?.isExpiringSoon ?? false;
  String? get accessToken => _currentSession?.accessToken;
  String? get refreshToken => _currentSession?.refreshToken;

  void debugSessionState() {
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    if (_currentSession != null) {
      // Session state available
    }
  }

  Future<void> createSession({
    required UserInfoEntity user,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    bool rememberMe = true,
  }) async {
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print

    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    // Removed debug print

    _currentSession = AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      rememberMe: rememberMe,
    );

    // Removed debug print

    // SIEMPRE GUARDAR
    await _saveSessionToStorage();

    // Removed debug print
    // Removed debug print
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
    // Removed debug print
  }

  Future<void> updateUser(UserInfoEntity user) async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para actualizar');
    }

    _currentSession = _currentSession!.copyWith(user: user);
    await _saveSessionToStorage();
    // Removed debug print
  }

  Future<void> clearSession() async {
    // Removed debug print
    _currentSession = null;
    await _clearStorageData();
    // Removed debug print
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
      // Removed debug print
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
    // Removed debug print

    try {
      if (_prefs == null) {
        // Removed debug print
        return;
      }

      final accessToken = _prefs!.getString(ApiConstants.accessTokenKey);
      final refreshToken = _prefs!.getString(ApiConstants.refreshTokenKey);
      final userDataString = _prefs!.getString(ApiConstants.userDataKey);

      // Removed debug print
      // Removed debug print
      // Removed debug print

      if (accessToken == null ||
          refreshToken == null ||
          userDataString == null) {
        // Removed debug print
        return;
      }

      // Removed debug print
      final userMap = jsonDecode(userDataString) as Map<String, dynamic>;
      // Removed debug print // 👈 AGREGAR para debug

      // 🔧 CORRECCIÓN: Usar nombres exactos de la API
      final user = UserInfoEntity(
        id: userMap['id']?.toString() ?? '',
        name: userMap['name'] ?? '',
        lastName: userMap['lastname'] ?? '',
        secondLastName: userMap['second_lastname'],
        username: userMap['username'] ?? '',
        email: userMap['email'] ?? '',
        job: userMap['job'] ?? '',
        phoneNumber: userMap['phone_number'] ?? '',
        role: userMap['role'] ?? '',
        verified: userMap['verified'] ?? false,
        isActive: userMap['active'] ?? true,
      );

      // Removed debug print

      final tokenPayload = getTokenPayload(accessToken);
      final exp = tokenPayload?['exp'] as int?;
      final expiresAt =
          exp != null
              ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
              : DateTime.now().add(const Duration(hours: 24));

      // Removed debug print

      _currentSession = AuthSession(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        rememberMe: true,
      );

      if (_currentSession!.isExpired) {
        // Removed debug print
        await clearSession();
        return;
      }

      // Removed debug print
      // Removed debug print
    } catch (e, stackTrace) {
      // Removed debug print
      // Removed debug print
      await _clearStorageData();
    }
  }

  Future<void> _saveSessionToStorage() async {
    // Removed debug print

    if (_currentSession == null) {
      // Removed debug print
      return;
    }

    if (_prefs == null) {
      // Removed debug print
      return;
    }

    try {
      // Removed debug print
      await _prefs!.setString(
        ApiConstants.accessTokenKey,
        _currentSession!.accessToken,
      );

      // Removed debug print
      await _prefs!.setString(
        ApiConstants.refreshTokenKey,
        _currentSession!.refreshToken,
      );

      // 🔧 CORRECCIÓN: Usar nombres exactos de la API
      final userMap = {
        'id': _currentSession!.user.id,
        'name': _currentSession!.user.name,
        'lastname':
            _currentSession!.user.lastName, // 👈 CAMBIO: 'lastname' (sin _)
        'second_lastname':
            _currentSession!
                .user
                .secondLastName, // 👈 CAMBIO: 'second_lastname' (con _)
        'username': _currentSession!.user.username,
        'email': _currentSession!.user.email,
        'phone_number': _currentSession!.user.phoneNumber,
        'role': _currentSession!.user.role,
        'verified': _currentSession!.user.verified,
        'active':
            _currentSession!
                .user
                .isActive, // 👈 CAMBIO: 'active' (no is_active)
      };

      // Removed debug print
      // Removed debug print // 👈 AGREGAR para debug
      await _prefs!.setString(ApiConstants.userDataKey, jsonEncode(userMap));

      // VERIFICAR QUE SE GUARDÓ
      final savedToken = _prefs!.getString(ApiConstants.accessTokenKey);
      final savedUser = _prefs!.getString(ApiConstants.userDataKey);

      // Removed debug print
      // Removed debug print
      // Removed debug print
      // Removed debug print // 👈 AGREGAR para debug

      if (savedToken != null && savedUser != null) {
        // Removed debug print
      } else {
        // Removed debug print
      }
    } catch (e) {
      // Removed debug print
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
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }
}
