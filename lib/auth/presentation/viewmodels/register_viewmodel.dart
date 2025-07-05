import 'package:flutter/foundation.dart';
import 'package:safy/auth/domain/usecases/sign_up_use_case.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../../domain/value_objects/job_type.dart';
import '../../domain/value_objects/gender.dart';

class RegisterViewModel extends ChangeNotifier {
  final SignUpUseCase _signUpUseCase;

  RegisterViewModel(this._signUpUseCase);

  // Estado del formulario - Página 1 (Datos personales)
  String _name = '';
  String _lastName = '';
  String _secondLastName = '';
  String _username = '';
  int _age = 18;
  Gender _selectedGender = Gender.preferNotToSay;

  // Estado del formulario - Página 2 (Cuenta y trabajo)
  JobType _selectedJobType = JobType.student;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
  JobType get selectedJobType => _selectedJobType;
  String get email => _email;
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
  
  // Validaciones de página
  bool get canGoToNextPage {
    return _name.isNotEmpty && 
           _lastName.isNotEmpty && 
           _username.isNotEmpty && 
           _age >= 13;
  }

  bool get canSubmit {
    return canGoToNextPage &&
           _email.isNotEmpty &&
           _password.isNotEmpty &&
           _confirmPassword.isNotEmpty &&
           !_isLoading;
  }

  // Setters - Página 1
  void setName(String name) {
    _name = name;
    _clearFieldError('name');
    notifyListeners();
  }

  void setLastName(String lastName) {
    _lastName = lastName;
    _clearFieldError('lastName');
    notifyListeners();
  }

  void setSecondLastName(String secondLastName) {
    _secondLastName = secondLastName;
    notifyListeners();
  }

  void setUsername(String username) {
    _username = username;
    _clearFieldError('username');
    notifyListeners();
  }

  void setAge(int age) {
    _age = age;
    _clearFieldError('age');
    notifyListeners();
  }

  void setGender(Gender gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  // Setters - Página 2
  void setJobType(JobType jobType) {
    _selectedJobType = jobType;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _clearFieldError('email');
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    _clearFieldError('password');
    notifyListeners();
  }

  void setConfirmPassword(String confirmPassword) {
    _confirmPassword = confirmPassword;
    _clearFieldError('confirmPassword');
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // Navegación entre páginas
  void nextPage() {
    if (_currentPage < 1 && canGoToNextPage) {
      _currentPage++;
      _clearError();
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _clearError();
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page <= 1) {
      _currentPage = page;
      _clearError();
      notifyListeners();
    }
  }

  // Limpiar errores
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      _fieldErrors.remove(field);
      notifyListeners();
    }
  }

  void clearError() => _clearError();

  // Limpiar formulario completo
  void clearForm() {
    _name = '';
    _lastName = '';
    _secondLastName = '';
    _username = '';
    _age = 18;
    _selectedGender = Gender.preferNotToSay;
    _selectedJobType = JobType.student;
    _email = '';
    _password = '';
    _confirmPassword = '';
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _currentPage = 0;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();
  }

  // Obtener error específico de campo
  String? getFieldError(String field) {
    return _fieldErrors[field];
  }

  // Método principal de registro
  Future<bool> signUp() async {
    if (!canSubmit) return false;

    _setLoading(true);
    _clearError();
    _fieldErrors.clear();

    try {
      final session = await _signUpUseCase.execute(
        name: _name,
        lastName: _lastName,
        secondLastName: _secondLastName.isNotEmpty ? _secondLastName : null,
        username: _username,
        age: _age,
        gender: _selectedGender.value,
        jobType: _selectedJobType.value,
        email: _email,
        password: _password,
        confirmPassword: _confirmPassword,
      );

      _lastSuccessfulSession = session;
      
      print('[RegisterViewModel] Registro exitoso para: ${session.user.username}');
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
      print('[RegisterViewModel] Error inesperado: $e');
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
      e.fieldErrors.map((key, errors) => MapEntry(key, errors.first))
    );
    
    // Si hay errores en la primera página, regresar a ella
    final page1Fields = ['name', 'lastName', 'username', 'age'];
    final hasPage1Errors = page1Fields.any((field) => _fieldErrors.containsKey(field));
    
    if (hasPage1Errors && _currentPage == 1) {
      _currentPage = 0;
    }

    _setError(e.message);
  }
} 