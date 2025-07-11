import '../entities/report.dart';
import '../repositories/report_repository.dart';
import '../exceptions/report_exceptions.dart';

class PostReport {
  final ReportRepository _repository;

  PostReport(this._repository);

  Future<ReportInfoEntity> execute({
    required String title,
    required String userName,
    required String incidentType,
    required String location,
    required DateTime dateTime,
    required String description,
 
    
  }) async {
    // Validaciones de negocio
    _validateReportData(
      title: title,
      userName:userName,
      incidentType: incidentType,
      location: location,
      dateTime:dateTime,
      description: description
    );

    return await _repository.createReport(
      title: title.trim(),
      userName: userName.trim(),
      incidentType: incidentType.trim(),
      dateTime: dateTime,
      location: location.trim(),
      description: description.trim(),
    );
  }

  void _validateReportData({
    required String title,
    required String description,
    required String userName,
    required String incidentType,
    required String location,
    required DateTime dateTime
    
  }) {
    final errors = <String, List<String>>{};

    // Validar título
    if (title.trim().isEmpty) {
      errors['title'] = ['El título es requerido'];
    }

    // Validar descripción
    if (description.trim().isEmpty) {
      errors['description'] = ['La descripción es requerida'];
    }

    // Validar nombre de usuario
    if (userName.trim().isEmpty) {
      errors['userName'] = ['El nombre de usuario es requerido'];
    }

    // Validar tipo de incidente
    if (incidentType.trim().isEmpty) {
      errors['incidentType'] = ['El tipo de incidente es requerido'];
    }

    // Validar fecha y hora
    if (dateTime.isBefore(DateTime.now())) {
      errors['dateTime'] = ['La fecha y hora no pueden ser en el pasado'];
    }

    // Validar ubicación
    if (location.trim().isEmpty) {
      errors['location'] = ['La ubicación es requerida'];
    }

    // Si hay errores, lanzar una excepción
    if (errors.isNotEmpty) {
      throw ReportValidationException('Errores de validacion', errors);
    }
  }
}