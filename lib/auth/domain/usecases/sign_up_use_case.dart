import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../exceptions/auth_exceptions.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<AuthSession> execute({
    required String name,
    required String lastName,
    String? secondLastName,
    required String username,
    required int age,
    required String gender,
    required String job,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber, 
    required String role,
  }) async {
    // Validaciones de negocio
    _validateRegistrationData(
      name: name,
      lastName: lastName,
      username: username,
      age: age,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phoneNumber: null,
      job: job,
      role: role,
    );

    return await _repository.signUp(
      name: name.trim(),
      lastName: lastName.trim(),
      secondLastName: secondLastName?.trim(),
      username: username.trim().toLowerCase(),
      age: age,
      gender: gender,
      role: role,
      job: job,
      email: email.trim().toLowerCase(),
      password: password,
      confirmPassword: confirmPassword,
      phoneNumber: null,
    );
  }

  void _validateRegistrationData({
    required String name,
    required String lastName,
    required String username,
    required int age,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    required String job,
    required String role,
  }) {
    final errors = <String, List<String>>{};

    // Validar nombre
    if (name.trim().isEmpty) {
      errors['name'] = ['El nombre es requerido'];
    } else if (name.trim().length < 2) {
      errors['name'] = ['El nombre debe tener al menos 2 caracteres'];
    }

    // Validar apellido
    if (lastName.trim().isEmpty) {
      errors['lastName'] = ['El apellido es requerido'];
    } else if (lastName.trim().length < 2) {
      errors['lastName'] = ['El apellido debe tener al menos 2 caracteres'];
    }

    // Validar username
    if (username.trim().isEmpty) {
      errors['username'] = ['El nombre de usuario es requerido'];
    } else if (username.trim().length < 3) {
      errors['username'] = ['El nombre de usuario debe tener al menos 3 caracteres'];
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      errors['username'] = ['El nombre de usuario solo puede contener letras, números y guiones bajos'];
    }

    // Validar edad
    if (age < 13) {
      errors['age'] = ['Debes tener al menos 13 años'];
    } else if (age > 120) {
      errors['age'] = ['Edad inválida'];
    }

    // Validar email
    if (email.trim().isEmpty) {
      errors['email'] = ['El correo electrónico es requerido'];
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim())) {
      errors['email'] = ['Formato de correo electrónico inválido'];
    }

    // Validar contraseña
    if (password.isEmpty) {
      errors['password'] = ['La contraseña es requerida'];
    } else if (password.length < 6) {
      errors['password'] = ['La contraseña debe tener al menos 6 caracteres'];
    }

    // Validar confirmación de contraseña
    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] = ['Debes confirmar la contraseña'];
    } else if (password != confirmPassword) {
      errors['confirmPassword'] = ['Las contraseñas no coinciden'];
    }

    if (errors.isNotEmpty) {
      throw ValidationException('Errores de validación', errors);
    }
  }
}