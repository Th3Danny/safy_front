import '../entities/report.dart';
import '../repositories/report_repository.dart';
import '../exceptions/report_exceptions.dart';

class PostReport {
  final ReportRepository _repository;

  PostReport(this._repository);

  Future<ReportInfoEntity> execute({
    required String title,
    required String description,
    required String incident_type,
    required double latitude,
    required double longitude,
    String? address,
    required String reporterName,
    String? reporterEmail,
    required int severity,
    required bool isAnonymous,
    // DateTime? dateTime,
  }) async {
    // Validaciones de negocio
    _validateReportData(
      title: title,
      description: description,
      incident_type: incident_type,
      latitude: latitude,
      longitude: longitude,
      reporterName: reporterName,
      reporterEmail: reporterEmail,
      severity: severity,
      //dateTime: dateTime,
    );

    return await _repository.createReport(
      title: title.trim(),
      description: description.trim(),
      incident_type: incident_type.trim(),
      latitude: latitude,
      longitude: longitude,
      address: address?.trim(),
      reporterName: reporterName.trim(),
      reporterEmail: reporterEmail?.trim(),
      severity: severity,
      isAnonymous: isAnonymous,
     // dateTime: dateTime,
    );
  }

  void _validateReportData({
    required String title,
    required String description,
    required String incident_type,
    required double latitude,
    required double longitude,
    required String reporterName,
    String? reporterEmail,
    required int severity,
    //required DateTime dateTime,
  }) {
    final errors = <String, List<String>>{};

    // Validar título
    if (title.trim().isEmpty) {
      errors['title'] = ['El título es requerido'];
    } else if (title.trim().length < 3) {
      errors['title'] = ['El título debe tener al menos 3 caracteres'];
    } else if (title.trim().length > 100) {
      errors['title'] = ['El título no puede exceder 100 caracteres'];
    }

    // Validar descripción
    if (description.trim().isEmpty) {
      errors['description'] = ['La descripción es requerida'];
    } else if (description.trim().length < 10) {
      errors['description'] = ['La descripción debe tener al menos 10 caracteres'];
    } else if (description.trim().length > 500) {
      errors['description'] = ['La descripción no puede exceder 500 caracteres'];
    }

    // Validar nombre del reportero
    if (reporterName.trim().isEmpty) {
      errors['reporterName'] = ['El nombre del reportero es requerido'];
    } else if (reporterName.trim().length < 2) {
      errors['reporterName'] = ['El nombre debe tener al menos 2 caracteres'];
    }

    // Validar email del reportero (si se proporciona)
    if (reporterEmail != null && reporterEmail.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(reporterEmail.trim())) {
        errors['reporterEmail'] = ['El formato del email no es válido'];
      }
    }

    // Validar tipo de incidente
    if (incident_type.trim().isEmpty) {
      errors['incidentType'] = ['El tipo de incidente es requerido'];
    }

    // Validar coordenadas
    if (latitude < -90 || latitude > 90) {
      errors['latitude'] = ['La latitud debe estar entre -90 y 90 grados'];
    }
    if (longitude < -180 || longitude > 180) {
      errors['longitude'] = ['La longitud debe estar entre -180 y 180 grados'];
    }

    // Validar severidad
    if (severity < 1 || severity > 5) {
      errors['severity'] = ['La severidad debe estar entre 1 y 5'];
    }

    // // Validar fecha y hora (permitir reportes hasta 1 hora en el pasado)
    // final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    // if (dateTime.isBefore(oneHourAgo)) {
    //   errors['dateTime'] = ['La fecha y hora no pueden ser anteriores a 1 hora'];
    // }
    
    // final futureLimit = DateTime.now().add(const Duration(days: 1));
    // if (dateTime.isAfter(futureLimit)) {
    //   errors['dateTime'] = ['La fecha y hora no pueden ser futuras'];
    //}

    // Si hay errores, lanzar una excepción
    if (errors.isNotEmpty) {
      throw ReportValidationException('Errores de validación', errors);
    }
  }
}