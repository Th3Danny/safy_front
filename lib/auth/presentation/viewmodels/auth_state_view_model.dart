import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:safy/auth/domain/usecases/sign_out_use_case.dart';
import 'package:safy/core/session/session_manager.dart';
import '../../domain/entities/user.dart';


/// ViewModel para manejar el estado global de autenticación
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

  // Getters
  UserInfoEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _sessionManager.isLoggedIn;
  bool get hasError => _errorMessage != null;

  // Inicializar estado de autenticación
  Future<void> initialize() async {
    _setLoading(true);

    try {
      if (_sessionManager.isLoggedIn) {
        _currentUser = await _getCurrentUserUseCase.execute();
        print('[AuthStateViewModel] Usuario cargado: ${_currentUser?.username}');
      }
    } catch (e) {
      print('[AuthStateViewModel] Error cargando usuario: $e');
      _setError('Error cargando datos del usuario');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar usuario después de login/registro
  void updateUser(UserInfoEntity user) {
    _currentUser = user;
    _clearError();
    notifyListeners();
  }

  // Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _signOutUseCase.execute();
      _currentUser = null;
      print('[AuthStateViewModel] Sesión cerrada');
    } catch (e) {
      print('[AuthStateViewModel] Error cerrando sesión: $e');
      _setError('Error cerrando sesión');
    } finally {
      _setLoading(false);
    }
  }

  // Refrescar datos del usuario
  Future<void> refreshUser() async {
    if (!_sessionManager.isLoggedIn) return;

    try {
      _currentUser = await _getCurrentUserUseCase.execute();
      _clearError();
      notifyListeners();
    } catch (e) {
      print('[AuthStateViewModel] Error refrescando usuario: $e');
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