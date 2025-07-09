import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<AuthSession> execute({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Validaciones básicas
    if (email.trim().isEmpty) {
      throw const InvalidEmailFormatException('El correo no puede estar vacío');
    }
    
    if (password.isEmpty) {
      throw const InvalidCredentialsException('La contraseña no puede estar vacía');
    }

    // Llamar al repositorio
    return await _repository.signIn(
      email: email.trim().toLowerCase(),
      password: password,
      
    );
  }
}