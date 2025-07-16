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
    print('[SessionManager] 🚀 INICIANDO initialize()...');

    if (_isInitialized) {
      print('[SessionManager] ⚠️ Ya está inicializado, saliendo...');
      return;
    }

    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      print('[SessionManager] ✅ SharedPreferences obtenido');

      await _loadStoredSession();

      _isInitialized = true;
      print('[SessionManager] ✅ Inicialización completada');
      print('[SessionManager] 📊 Estado final - isLoggedIn: $isLoggedIn');
    } catch (e) {
      print('[SessionManager] ❌ Error en initialize: $e');
      _isInitialized = true; // Marcar como inicializado aún con error
    }
  }

  AuthSession? get currentSession => _currentSession;
  UserInfoEntity? get currentUser => _currentSession?.user;

  bool get isLoggedIn {
    final hasSession = _currentSession != null;
    final isNotExpired = hasSession ? !_currentSession!.isExpired : false;
    final result = hasSession && isNotExpired;

    print('[SessionManager] 🔍 isLoggedIn check:');
    print('[SessionManager] 🔍   - hasSession: $hasSession');
    print('[SessionManager] 🔍   - isNotExpired: $isNotExpired');
    print('[SessionManager] 🔍   - result: $result');

    return result;
  }

  bool get isTokenExpiringSoon => _currentSession?.isExpiringSoon ?? false;
  String? get accessToken => _currentSession?.accessToken;
  String? get refreshToken => _currentSession?.refreshToken;

  void debugSessionState() {
    print('[SessionManager] 🔍 ========== DEBUG SESSION STATE ==========');
    print('[SessionManager] 🔍 _isInitialized: $_isInitialized');
    print(
      '[SessionManager] 🔍 _currentSession != null: ${_currentSession != null}',
    );
    print('[SessionManager] 🔍 isLoggedIn: $isLoggedIn');
    print(
      '[SessionManager] 🔍 currentUser: ${currentUser?.username ?? 'null'}',
    );
    print('[SessionManager] 🔍 accessToken presente: ${accessToken != null}');
    if (_currentSession != null) {
      print('[SessionManager] 🔍 isExpired: ${_currentSession!.isExpired}');
      print('[SessionManager] 🔍 expiresAt: ${_currentSession!.expiresAt}');
      print('[SessionManager] 🔍 now: ${DateTime.now()}');
    }
    print('[SessionManager] 🔍 ==========================================');
  }

  Future<void> createSession({
    required UserInfoEntity user,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    bool rememberMe = true,
  }) async {
    print('[SessionManager] 🔐 CREANDO SESIÓN...');
    print('[SessionManager] 👤 Usuario: ${user.username}');
    print('[SessionManager] 💾 RememberMe: $rememberMe');
    print('[SessionManager] ⏰ ExpiresIn: $expiresIn segundos');

    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    print('[SessionManager] 📅 Expira en: $expiresAt');

    _currentSession = AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      rememberMe: rememberMe,
    );

    print('[SessionManager] ✅ Sesión creada en memoria');

    // SIEMPRE GUARDAR
    await _saveSessionToStorage();

    print('[SessionManager] 🎉 Sesión completamente creada');
    print('[SessionManager] 📊 isLoggedIn después de crear: $isLoggedIn');
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

  Future<void> updateUser(UserInfoEntity user) async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para actualizar');
    }

    _currentSession = _currentSession!.copyWith(user: user);
    await _saveSessionToStorage();
    print('[SessionManager] Usuario actualizado: ${user.username}');
  }

  Future<void> clearSession() async {
    print('[SessionManager] 🧹 LIMPIANDO SESIÓN...');
    _currentSession = null;
    await _clearStorageData();
    print('[SessionManager] ✅ Sesión limpiada completamente');
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
  print('[SessionManager] 📖 CARGANDO SESIÓN ALMACENADA...');
  
  try {
    if (_prefs == null) {
      print('[SessionManager] ❌ SharedPreferences es null');
      return;
    }

    final accessToken = _prefs!.getString(ApiConstants.accessTokenKey);
    final refreshToken = _prefs!.getString(ApiConstants.refreshTokenKey);
    final userDataString = _prefs!.getString(ApiConstants.userDataKey);

    print('[SessionManager] 🔍 AccessToken encontrado: ${accessToken != null}');
    print('[SessionManager] 🔍 RefreshToken encontrado: ${refreshToken != null}');
    print('[SessionManager] 🔍 UserData encontrado: ${userDataString != null}');

    if (accessToken == null || refreshToken == null || userDataString == null) {
      print('[SessionManager] ⚠️ Datos incompletos - no hay sesión almacenada');
      return;
    }

    print('[SessionManager] 📝 Parseando datos de usuario...');
    final userMap = jsonDecode(userDataString) as Map<String, dynamic>;
    print('[SessionManager] 📝 UserMap: $userMap'); // 👈 AGREGAR para debug

    // 🔧 CORRECCIÓN: Usar nombres exactos de la API
    final user = UserInfoEntity(
      id: userMap['id']?.toString() ?? '',
      name: userMap['name'] ?? '',
      lastName: userMap['lastname'] ?? '', // 👈 CAMBIO: 'lastname' (sin _)
      secondLastName: userMap['second_lastname'], // 👈 CAMBIO: 'second_lastname' (con _)
      username: userMap['username'] ?? '',
      email: userMap['email'] ?? '',
      phoneNumber: userMap['phone_number'] ?? '',
      role: userMap['role'] ?? '',
      verified: userMap['verified'] ?? false,
      isActive: userMap['active'] ?? true, // 👈 CAMBIO: 'active' (no is_active)
    );

    print('[SessionManager] 👤 Usuario parseado: ${user.username}');

    final tokenPayload = getTokenPayload(accessToken);
    final exp = tokenPayload?['exp'] as int?;
    final expiresAt = exp != null
        ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
        : DateTime.now().add(const Duration(hours: 24));

    print('[SessionManager] ⏰ Token expira en: $expiresAt');

    _currentSession = AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      rememberMe: true,
    );

    if (_currentSession!.isExpired) {
      print('[SessionManager] ⚠️ Sesión expirada, limpiando...');
      await clearSession();
      return;
    }

    print('[SessionManager] ✅ SESIÓN CARGADA EXITOSAMENTE para: ${user.username}');
    print('[SessionManager] 📊 isLoggedIn después de cargar: $isLoggedIn');
    
  } catch (e, stackTrace) {
    print('[SessionManager] ❌ Error cargando sesión: $e');
    print('[SessionManager] 📍 StackTrace: $stackTrace');
    await _clearStorageData();
  }
}

  Future<void> _saveSessionToStorage() async {
    print('[SessionManager] 💾 GUARDANDO SESIÓN EN STORAGE...');

    if (_currentSession == null) {
      print('[SessionManager] ❌ No hay sesión para guardar');
      return;
    }

    if (_prefs == null) {
      print('[SessionManager] ❌ SharedPreferences es null');
      return;
    }

    try {
      print('[SessionManager] 🔑 Guardando access token...');
      await _prefs!.setString(
        ApiConstants.accessTokenKey,
        _currentSession!.accessToken,
      );

      print('[SessionManager] 🔑 Guardando refresh token...');
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

      print('[SessionManager] 👤 Guardando datos de usuario...');
      print(
        '[SessionManager] 📝 UserMap a guardar: $userMap',
      ); // 👈 AGREGAR para debug
      await _prefs!.setString(ApiConstants.userDataKey, jsonEncode(userMap));

      // VERIFICAR QUE SE GUARDÓ
      final savedToken = _prefs!.getString(ApiConstants.accessTokenKey);
      final savedUser = _prefs!.getString(ApiConstants.userDataKey);

      print('[SessionManager] ✅ GUARDADO VERIFICADO:');
      print('[SessionManager] 🔍 Token guardado: ${savedToken != null}');
      print('[SessionManager] 🔍 Usuario guardado: ${savedUser != null}');
      print(
        '[SessionManager] 📝 Usuario guardado data: $savedUser',
      ); // 👈 AGREGAR para debug

      if (savedToken != null && savedUser != null) {
        print('[SessionManager] 🎉 SESIÓN GUARDADA EXITOSAMENTE');
      } else {
        print('[SessionManager] ❌ ERROR: Datos no se guardaron correctamente');
      }
    } catch (e) {
      print('[SessionManager] ❌ Error guardando sesión: $e');
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
      print('[SessionManager] 🧹 Datos de almacenamiento limpiados');
    } catch (e) {
      print('[SessionManager] ❌ Error limpiando almacenamiento: $e');
    }
  }
}
