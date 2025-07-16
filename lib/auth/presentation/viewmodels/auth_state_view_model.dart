import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:safy/auth/domain/usecases/sign_out_use_case.dart';
import 'package:safy/core/session/session_manager.dart';
import '../../domain/entities/user.dart';

class AuthStateViewModel extends ChangeNotifier {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignOutUseCase _signOutUseCase;
  final SessionManager _sessionManager;

  AuthStateViewModel(
    this._getCurrentUserUseCase,
    this._signOutUseCase,
    this._sessionManager,
  );

  // Estado
  UserInfoEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  // Getters
  UserInfoEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _sessionManager.isLoggedIn;
  bool get hasError => _errorMessage != null;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
  if (_initialized) return;
  
  _setLoading(true);

  try {
    if (_sessionManager.isLoggedIn) {
      print('[AuthStateVM] 🔄 Intentando cargar usuario...');
      
      try {
        _currentUser = await _getCurrentUserUseCase.execute();
        print('[AuthStateVM] ✅ Usuario cargado: ${_currentUser?.username}');
      } catch (e) {
        print('[AuthStateVM] ⚠️ Error cargando usuario, usando datos de sesión: $e');
        // 🔧 CAMBIO: Usar datos del SessionManager si falla la API
        _currentUser = _sessionManager.currentUser;
        print('[AuthStateVM] 💾 Usuario tomado de SessionManager: ${_currentUser?.username}');
      }
    } else {
      print('[AuthStateVM]  No hay usuario logueado');
    }
    _initialized = true;
  } catch (e, stackTrace) {
    print('[AuthStateVM]  Error en initialize: $e');
    print(stackTrace);
    
    // 🔧 CAMBIO: No limpiar sesión por errores de red
    if (e is UnauthorizedException) {
      await _sessionManager.clearSession();
    }
    // No limpiar sesión por otros errores (como de red)
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}

  void updateUser(UserInfoEntity user) {
    _currentUser = user;
    _clearError();
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _signOutUseCase.execute();
      _currentUser = null;
      _initialized = false;
      print('[AuthStateVM] Sesión cerrada correctamente');
    } catch (e, stackTrace) {
      print('[AuthStateVM] Error cerrando sesión: $e');
      print(stackTrace);
      _setError('Error cerrando sesión');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (!_sessionManager.isLoggedIn) return;

    _setLoading(true);
    
    try {
      _currentUser = await _getCurrentUserUseCase.execute();
      _clearError();
      print('[AuthStateVM] Usuario refrescado');
    } catch (e, stackTrace) {
      print('[AuthStateVM] Error refrescando usuario: $e');
      print(stackTrace);
      _setError('Error actualizando datos');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() => _clearError();
}