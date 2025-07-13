class ReportExceptions implements Exception {
  final String message;
  final String? code;

  ReportExceptions(this.message, {this.code});

  @override
  String toString() {
    return 'ReportExceptions: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

// Exeptions específicas
class InvalidReportDataException extends ReportExceptions {
  InvalidReportDataException([String? message])
      : super(message ?? 'Datos del reporte inválidos');
}
class ReportNotFoundException extends ReportExceptions {
  ReportNotFoundException([String? message])
      : super(message ?? 'Reporte no encontrado');
}

class ReportCreationException extends ReportExceptions {
  ReportCreationException([String? message])
      : super(message ?? 'Error al crear el reporte');
}

class ReportValidationException extends ReportExceptions {
  final Map<String, List<String>> fieldErrors;

  ReportValidationException(
    String message,
    
    this.fieldErrors,
  ) : super(message, code: 'VALIDATION_ERROR');

  @override
  String toString() {
    final errors = fieldErrors.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join('\n');
    return 'ValidationException: $message\nErrors:\n$errors';
  }
}

  
