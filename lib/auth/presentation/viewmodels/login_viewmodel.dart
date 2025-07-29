import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/usecases/sign_in_use_case.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/core/services/device/device_registration_service.dart';
import 'package:safy/core/services/firebase/firebase_messaging_service.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/exceptions/auth_exceptions.dart';

class LoginViewModel extends ChangeNotifier {
  final SignInUseCase _signInUseCase;
  final DeviceRegistrationService _deviceRegistrationService =
      DeviceRegistrationService();
  final FirebaseMessagingService _firebaseMessagingService =
      FirebaseMessagingService();

  LoginViewModel(this._signInUseCase);

  // Estado del formulario
  String _email = '';
  String _password = '';
  bool _rememberMe = true;
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
  bool get canSubmit =>
      _email.isNotEmpty && _password.isNotEmpty && !_isLoading;

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
      // Removed debug print
      final session = await _signInUseCase.execute(
        email: _email,
        password: _password,
      );

      // Removed debug print
      // Removed debug print
      print(
        '[LoginViewModel] 🔑 Token recibido: ${session.accessToken.substring(0, 20)}...',
      );
      // Removed debug print

      // Calcular expiresIn en segundos
      final expiresIn = session.expiresAt.difference(DateTime.now()).inSeconds;
      // Removed debug print

      // Removed debug print
      await SessionManager.instance.createSession(
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresIn: expiresIn,
        rememberMe: _rememberMe,
      );

      // Removed debug print

      // Verificar inmediatamente el estado del SessionManager
      final sessionManager = SessionManager.instance;
      // Removed debug print
      // Removed debug print
      // Removed debug print
      // Removed debug print

      _lastSuccessfulSession = session;

      // Limpiar contraseña por seguridad pero mantener email si rememberMe está activo
      _password = '';
      if (!_rememberMe) {
        _email = '';
      }

      // Removed debug print
      // Removed debug print

      // 📱 Registrar dispositivo después del login exitoso
      await _registerDeviceAfterLogin();

      return true;
    } on ValidationException catch (e) {
      // Removed debug print
      _setError(_formatValidationError(e));
      return false;
    } on InvalidCredentialsException catch (e) {
      // Removed debug print
      _setError(e.message);
      return false;
    } on AuthException catch (e) {
      // Removed debug print
      _setError(e.message);
      return false;
    } catch (e) {
      // Removed debug print
      _setError('Error inesperado. Intenta nuevamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Método para obtener la ubicación actual
  Future<Location?> _getCurrentLocation() async {
    try {
      // Removed debug print

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Removed debug print
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Removed debug print
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Removed debug print
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      // Removed debug print
      return location;
    } catch (e) {
      // Removed debug print
      return null;
    }
  }

  // Método para registrar el dispositivo después del login
  Future<void> _registerDeviceAfterLogin() async {
    try {
      // Removed debug print

      // Obtener FCM token
      final fcmToken = await _firebaseMessagingService.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        // Removed debug print
        return;
      }

      print(
        '[LoginViewModel] 🔐 FCM Token obtenido: ${fcmToken.substring(0, 20)}...',
      );

      // Intentar obtener ubicación actual
      final location = await _getCurrentLocation();

      if (location != null) {
        await _deviceRegistrationService.registerDevice(
          fcmToken: fcmToken,
          location: location,
        );
      } else {
        // Usar ubicación por defecto si no se puede obtener la ubicación
        await _deviceRegistrationService.registerDeviceWithDefaultLocation(
          fcmToken: fcmToken,
        );
      }
    } catch (e) {
      // Removed debug print
      // No lanzar excepción para no interrumpir el flujo de login
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
    final firstErrors =
        e.fieldErrors.values
            .where((errors) => errors.isNotEmpty)
            .map((errors) => errors.first)
            .toList();

    return firstErrors.isNotEmpty ? firstErrors.first : e.message;
  }
}
