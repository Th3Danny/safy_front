import 'package:safy/report/domain/entities/report.dart';

class ReportResponseDto {
  final int id;
  final String title;
  final String description;
  final String incidentType;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final String reporterName;
  final bool isAnonymous;
  final int severity;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final String? comments;

  const ReportResponseDto({
    required this.id,
    required this.title,
    required this.description,
    required this.incidentType,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.reporterName,
    required this.isAnonymous,
    required this.severity,
    this.imageUrl,
    this.audioUrl,
    this.createdAt,
    this.updatedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.comments,
  });

  factory ReportResponseDto.fromJson(Map<String, dynamic> json) {
    // 🔥 LA RESPUESTA REAL: el reporte está directamente en 'data'
    final data = json['data'] as Map<String, dynamic>;
    
    return ReportResponseDto(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      incidentType: data['incident_type'],
      status: data['status'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'],
      reporterName: data['reporter_name'],
      isAnonymous: data['is_anonymous'],
      severity: data['severity'],
      imageUrl: data['image_url'],
      audioUrl: data['audio_url'],
      // 🔥 CAMPOS NULLABLE - pueden ser null según tu respuesta
      createdAt: data['created_at'] != null ? _parseDateTime(data['created_at']) : null,
      updatedAt: data['updated_at'] != null ? _parseDateTime(data['updated_at']) : null,
      verifiedBy: data['verified_by'],
      verifiedAt: data['verified_at'] != null ? _parseDateTime(data['verified_at']) : null,
      verificationNotes: data['verification_notes'],
      resolvedBy: data['resolved_by'],
      resolvedAt: data['resolved_at'] != null ? _parseDateTime(data['resolved_at']) : null,
      resolutionNotes: data['resolution_notes'],
      comments: data['comments'],
    );
  }

  // 🔥 MÉTODO PARA PARSEAR FECHAS (maneja null y diferentes formatos)
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    // Si es un array (formato Java LocalDateTime)
    if (dateValue is List && dateValue.length >= 6) {
      try {
        return DateTime(
          dateValue[0], // year
          dateValue[1], // month
          dateValue[2], // day
          dateValue[3], // hour
          dateValue[4], // minute
          dateValue[5], // second
          (dateValue.length > 6 ? dateValue[6] ~/ 1000000 : 0), // milliseconds
        );
      } catch (e) {
        print('[ReportResponseDto] Error parseando fecha array: $e');
        return null;
      }
    }
    
    // Si es un string ISO
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('[ReportResponseDto] Error parseando fecha string: $e');
        return null;
      }
    }
    
    return null;
  }

  // 🔥 CONVERTIR A ENTIDAD DE DOMINIO
  ReportInfoEntity toDomainEntity() {
    return ReportInfoEntity(
      title: title,
      description: description,
      incident_type: incidentType,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reporterName: reporterName,
      reporterEmail: null, // El backend no devuelve email en la respuesta
      severity: severity,
      isAnonymous: isAnonymous,
      //dateTime: createdAt ?? DateTime.now(), // Usar createdAt o fecha actual
    );
  }

  @override
  String toString() {
    return 'ReportResponseDto('
        'id: $id, '
        'title: $title, '
        'status: $status, '
        'incidentType: $incidentType, '
        'severity: $severity'
        ')';
  }
}