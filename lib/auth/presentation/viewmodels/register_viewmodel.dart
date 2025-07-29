import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/usecases/sign_up_use_case.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../../domain/value_objects/job_type.dart';
import '../../domain/value_objects/gender.dart';

class RegisterViewModel extends ChangeNotifier {
  final SignUpUseCase _signUpUseCase;

  RegisterViewModel(this._signUpUseCase) {
    // Removed debug print
  }

  // Estado del formulario - Página 1 (Datos personales)
  String _name = '';
  String _lastName = '';
  String _secondLastName = '';
  String _username = '';
  int _age = 18;
  Gender _selectedGender = Gender.preferNotToSay;

  // Estado del formulario - Página 2 (Cuenta y trabajo)
  Job _selectedJobType = Job.student;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _phoneNumber;
  String? _fcmToken;

  // Estado de la UI
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};
  int _currentPage = 0;
  AuthSession? _lastSuccessfulSession;

  // Getters - Página 1
  String get name => _name;
  String get lastName => _lastName;
  String get secondLastName => _secondLastName;
  String get username => _username;
  int get age => _age;
  Gender get selectedGender => _selectedGender;

  // Getters - Página 2
  Job get selectedJobType => _selectedJobType;
  String get email => _email;
  String get phoneNumber => _phoneNumber ?? '';
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  // Getters - UI State
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;
  int get currentPage => _currentPage;
  AuthSession? get lastSuccessfulSession => _lastSuccessfulSession;
  bool get hasError => _errorMessage != null;

  // 🔧 Validaciones de página mejoradas
  bool get canGoToNextPage {
    final isValid =
        _name.isNotEmpty &&
        _lastName.isNotEmpty &&
        _username.isNotEmpty &&
        _username.length >= 3 &&
        _age >= 13;

    return isValid;
  }

  bool get canSubmit {
    final isValid =
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _password == _confirmPassword &&
        !_isLoading;

    return isValid;
  }

  // Setters - Página 1
  void setName(String name) {
    final trimmedName = name.trim();
    if (_name != trimmedName) {
      _name = trimmedName;
      _clearFieldError('name');
      notifyListeners();
    }
  }

  void setLastName(String lastName) {
    final trimmedLastName = lastName.trim();
    if (_lastName != trimmedLastName) {
      _lastName = trimmedLastName;
      _clearFieldError('lastName');
      print(
        '[RegisterViewModel] setLastName: "$_lastName" (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void setSecondLastName(String secondLastName) {
    final trimmedSecondLastName = secondLastName.trim();
    if (_secondLastName != trimmedSecondLastName) {
      _secondLastName = trimmedSecondLastName;
      print(
        '[RegisterViewModel] setSecondLastName: "$_secondLastName" (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void setUsername(String username) {
    final trimmedUsername = username.trim().toLowerCase();
    if (_username != trimmedUsername) {
      _username = trimmedUsername;
      _clearFieldError('username');
      print(
        '[RegisterViewModel] setUsername: "$_username" (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void setAge(int age) {
    if (_age != age && age >= 13 && age <= 120) {
      _age = age;
      _clearFieldError('age');
      print('[RegisterViewModel] setAge: $_age (hashCode: ${hashCode})');
      notifyListeners();
    }
  }

  void setGender(Gender gender) {
    if (_selectedGender != gender) {
      _selectedGender = gender;
      print(
        '[RegisterViewModel] setGender: ${_selectedGender.value} (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  // Setters - Página 2
  void setJobType(Job jobType) {
    if (_selectedJobType != jobType) {
      _selectedJobType = jobType;
      print(
        '[RegisterViewModel] setJobType: ${_selectedJobType.value} (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void setEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    if (_email != trimmedEmail) {
      _email = trimmedEmail;
      _clearFieldError('email');
      print('[RegisterViewModel] setEmail: "$_email" (hashCode: ${hashCode})');
      notifyListeners();
    }
  }

  void setPassword(String password) {
    if (_password != password) {
      _password = password;
      _clearFieldError('password');
      print(
        '[RegisterViewModel] setPassword: "${password.isNotEmpty ? "***" : ""}" (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void setConfirmPassword(String confirmPassword) {
    if (_confirmPassword != confirmPassword) {
      _confirmPassword = confirmPassword;
      _clearFieldError('confirmPassword');
      print(
        '[RegisterViewModel] setConfirmPassword: "${confirmPassword.isNotEmpty ? "***" : ""}" (hashCode: ${hashCode})',
      );
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setFcmToken(String? token) {
    _fcmToken = token;
    // Removed debug print
  }

  // 🔧 Navegación entre páginas - SIN notifyListeners automático
  void nextPage() {
    if (_currentPage < 1 && canGoToNextPage) {
      _currentPage++;
      _clearError(); // SOLO limpiar errores, NO datos
      print(
        '[RegisterViewModel] nextPage: $_currentPage (hashCode: ${hashCode})',
      );
      // 🔧 NO llamar notifyListeners() aquí para evitar setState durante navegación
    } else {
      print(
        '[RegisterViewModel] nextPage: No se puede avanzar. canGoToNextPage: $canGoToNextPage (hashCode: ${hashCode})',
      );
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _clearError(); // SOLO limpiar errores, NO datos
      print(
        '[RegisterViewModel] previousPage: $_currentPage (hashCode: ${hashCode})',
      );
      // 🔧 NO llamar notifyListeners() aquí para evitar setState durante navegación
    }
  }

  // 🔧 goToPage SIN notifyListeners para evitar conflictos durante initState
  void goToPage(int page) {
    if (page >= 0 && page <= 1) {
      _currentPage = page;
      _clearError(); // SOLO limpiar errores, NO datos
      print(
        '[RegisterViewModel] goToPage: $_currentPage (hashCode: ${hashCode})',
      );
      // 🔍 Imprimir estado actual después del cambio de página
      printCurrentState();
      // 🔧 NO llamar notifyListeners() aquí para evitar setState durante initState
    }
  }

  // 🔧 Método para forzar rebuild después de navegación (llamar desde UI)
  void notifyPageChange() {
    notifyListeners();
  }

  // Limpiar errores - NO notificar automáticamente
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors.remove(field);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Limpiar formulario completo
  void clearForm() {
    print(
      '[RegisterViewModel] clearForm: Limpiando formulario (hashCode: ${hashCode})',
    );
    _name = '';
    _lastName = '';
    _secondLastName = '';
    _username = '';
    _age = 18;
    _selectedGender = Gender.preferNotToSay;
    _selectedJobType = Job.student;
    _email = '';
    _phoneNumber = null;
    _password = '';
    _confirmPassword = '';
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _currentPage = 0;
    _errorMessage = null;
    _fieldErrors.clear();
    _lastSuccessfulSession = null;
    notifyListeners();
  }

  // Obtener error específico de campo
  String? getFieldError(String field) {
    return _fieldErrors[field];
  }

  // 🔍 Método para imprimir estado actual (debug)
  void printCurrentState() {
    print('=== REGISTER VIEWMODEL STATE (hashCode: ${hashCode}) ===');
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
    // Removed debug print
  }

  // Método principal de registro
  Future<bool> signUp() async {
    if (!canSubmit) {
      print(
        '[RegisterViewModel] signUp: No se puede enviar. canSubmit: $canSubmit (hashCode:  [${hashCode})',
      );
      return false;
    }

    _setLoading(true);
    _clearError();
    _fieldErrors.clear();

    try {
      // 🔍 Imprimir estado antes de enviar
      print(
        '[RegisterViewModel] Intentando registrar con los siguientes datos (hashCode:  [${hashCode}):',
      );
      printCurrentState();
      // Removed debug print

      final session = await _signUpUseCase.execute(
        name: _name,
        lastName: _lastName,
        secondLastName: _secondLastName.isNotEmpty ? _secondLastName : null,
        username: _username,
        age: _age,
        gender: _selectedGender.value,
        job: _selectedJobType.value,
        email: _email,
        password: _password,
        confirmPassword: _confirmPassword,
        phoneNumber: null,
        role: 'CITIZEN', // Asignar rol por defecto
        fcmToken: _fcmToken,
      );

      _lastSuccessfulSession = session;

      print(
        '[RegisterViewModel] Registro exitoso para: ${session.user.username} (hashCode: ${hashCode})',
      );

      return true;
    } on ValidationException catch (e) {
      _handleValidationError(e);
      return false;
    } on EmailAlreadyExistsException catch (e) {
      _setError(e.message);
      _fieldErrors['email'] = e.message;
      return false;
    } on UsernameAlreadyExistsException catch (e) {
      _setError(e.message);
      _fieldErrors['username'] = e.message;
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error inesperado durante el registro. Intenta nuevamente.');
      print('[RegisterViewModel] Error inesperado: $e (hashCode: ${hashCode})');
      return false;
    } finally {
      _setLoading(false);
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

  void _handleValidationError(ValidationException e) {
    _fieldErrors = Map<String, String>.from(
      e.fieldErrors.map((key, errors) => MapEntry(key, errors.first)),
    );

    // Si hay errores en la primera página, regresar a ella
    final page1Fields = ['name', 'lastName', 'username', 'age'];
    final hasPage1Errors = page1Fields.any(
      (field) => _fieldErrors.containsKey(field),
    );

    if (hasPage1Errors && _currentPage == 1) {
      _currentPage = 0;
      print(
        '[RegisterViewModel] Errores en página 1, regresando... (hashCode: ${hashCode})',
      );
    }

    _setError(e.message);
  }
}
