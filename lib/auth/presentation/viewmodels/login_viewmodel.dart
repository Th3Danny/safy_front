import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/usecases/sign_in_use_case.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/exceptions/auth_exceptions.dart';

class LoginViewModel extends ChangeNotifier {
  final SignInUseCase _signInUseCase;

  LoginViewModel(this._signInUseCase);

  // Estado del formulario
  String _email = '';
  String _password = '';
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  // Estado de la UI
  bool _isLoading = false;
  String? _errorMessage;
  AuthSession? _lastSuccessfulSession;

  // Getters para el estado del formulario
  String get email => _email;
  String get password => _password;
  bool get rememberMe => _rememberMe;
  bool get isPasswordVisible => _isPasswordVisible;

  // Getters para el estado de la UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthSession? get lastSuccessfulSession => _lastSuccessfulSession;
  bool get hasError => _errorMessage != null;
  bool get canSubmit => _email.isNotEmpty && _password.isNotEmpty && !_isLoading;

  // Setters para el formulario
  void setEmail(String email) {
    _email = email;
    _clearError();
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    _clearError();
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // Limpiar error
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() => _clearError();

  // Limpiar formulario
  void clearForm() {
    _email = '';
    _password = '';
    _rememberMe = false;
    _isPasswordVisible = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Método principal de login
  Future<bool> signIn() async {
    if (!canSubmit) return false;

    _setLoading(true);
    _clearError();

    try {
      final session = await _signInUseCase.execute(
        email: _email,
        password: _password,
    
      );

      _lastSuccessfulSession = session;
      
      // Limpiar contraseña por seguridad pero mantener email si rememberMe está activo
      _password = '';
      if (!_rememberMe) {
        _email = '';
      }
      
      print('[LoginViewModel] Login exitoso para: ${session.user.username}');
      return true;

    } on ValidationException catch (e) {
      _setError(_formatValidationError(e));
      return false;
    } on InvalidCredentialsException catch (e) {
      _setError(e.message);
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error inesperado. Intenta nuevamente.');
      print('[LoginViewModel] Error inesperado: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Precargar email si existe en preferencias
  void preloadEmailIfRemembered(String? savedEmail) {
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _email = savedEmail;
      _rememberMe = true;
      notifyListeners();
    }
  }

  // ===== MÉTODOS PRIVADOS =====

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  String _formatValidationError(ValidationException e) {
    if (e.fieldErrors.isEmpty) return e.message;
    
    // Tomar el primer error de cada campo
    final firstErrors = e.fieldErrors.values
        .where((errors) => errors.isNotEmpty)
        .map((errors) => errors.first)
        .toList();
    
    return firstErrors.isNotEmpty ? firstErrors.first : e.message;
  }
}
