class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() {
    return 'ApiException(message: $message, code: $code, statusCode: $statusCode)';
  }
}
