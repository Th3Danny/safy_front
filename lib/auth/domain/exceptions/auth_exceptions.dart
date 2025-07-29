class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Excepciones específicas
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([String? message])
      : super(message ?? 'Credenciales inválidas', code: 'INVALID_CREDENTIALS');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException([String? message])
      : super(message ?? 'Usuario no encontrado', code: 'USER_NOT_FOUND');
}

class EmailAlreadyExistsException extends AuthException {
  const EmailAlreadyExistsException([String? message])
      : super(message ?? 'El correo electrónico ya está registrado', code: 'EMAIL_EXISTS');
}

class UsernameAlreadyExistsException extends AuthException {
  const UsernameAlreadyExistsException([String? message])
      : super(message ?? 'El nombre de usuario ya está en uso', code: 'USERNAME_EXISTS');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException([String? message])
      : super(message ?? 'La contraseña es muy débil', code: 'WEAK_PASSWORD');
}

class InvalidEmailFormatException extends AuthException {
  const InvalidEmailFormatException([String? message])
      : super(message ?? 'Formato de correo electrónico inválido', code: 'INVALID_EMAIL_FORMAT');
}

class TokenExpiredException extends AuthException {
  const TokenExpiredException([String? message])
      : super(message ?? 'Token expirado', code: 'TOKEN_EXPIRED');
}

class InvalidTokenException extends AuthException {
  const InvalidTokenException([String? message])
      : super(message ?? 'Token inválido', code: 'INVALID_TOKEN');
}

class AccountNotActiveException extends AuthException {
  const AccountNotActiveException([String? message])
      : super(message ?? 'Cuenta no activa', code: 'ACCOUNT_NOT_ACTIVE');
}

class PasswordMismatchException extends AuthException {
  const PasswordMismatchException([String? message])
      : super(message ?? 'Las contraseñas no coinciden', code: 'PASSWORD_MISMATCH');
}

// Añade estas nuevas clases de excepción junto con las existentes
class UnauthorizedException extends AuthException {
  const UnauthorizedException([String? message])
      : super(message ?? 'No autorizado', code: 'UNAUTHORIZED');
}

class InvalidSessionException extends AuthException {
  const InvalidSessionException([String? message])
      : super(message ?? 'Sesión inválida o expirada', code: 'INVALID_SESSION');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException([String? message])
      : super(message ?? 'Demasiados intentos. Por favor intente más tarde', 
             code: 'TOO_MANY_REQUESTS');
}

class ValidationException extends AuthException {
  final Map<String, List<String>> fieldErrors;

  const ValidationException(
    super.message,
    this.fieldErrors,
  ) : super(code: 'VALIDATION_ERROR');

  @override
  String toString() {
    final errors = fieldErrors.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join('\n');
    return 'ValidationException: $message\nErrors:\n$errors';
  }
}
