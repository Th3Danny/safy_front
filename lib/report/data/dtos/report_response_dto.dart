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
  final int? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final int? resolvedBy;
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

  /// Factory method to create a ReportResponseDto from a JSON map representing a single report.
  factory ReportResponseDto.fromJson(Map<String, dynamic> json) {
    // CORREGIDO: Elimina la línea `final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;`
    // y accede directamente a las propiedades del mapa `json`
    // porque este `json` ya es el objeto de un reporte individual.
    return ReportResponseDto(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      incidentType: json['incident_type'] as String,
      status: json['status'] as String,
      latitude: (json['latitude'] as num).toDouble(), // Casteo seguro para double
      longitude: (json['longitude'] as num).toDouble(), // Casteo seguro para double
      address: json['address'] as String?, // Nullable string, usa 'as String?'
      reporterName: json['reporter_name'] as String,
      isAnonymous: json['is_anonymous'] as bool,
      severity: (json['severity'] as num).toInt(), // Casteo seguro para int
      imageUrl: json['image_url'] as String?, // Nullable string
      audioUrl: json['audio_url'] as String?, // Nullable string

      // Manejo de DateTime, proporcionando null si el valor del JSON es null
      createdAt: json['created_at'] != null ? _parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? _parseDateTime(json['updated_at']) : null,

      // Campos int nulos
      verifiedBy: (json['verified_by'] as num?)?.toInt(), // Casteo seguro para int nulo
      verifiedAt: json['verified_at'] != null ? _parseDateTime(json['verified_at']) : null,
      verificationNotes: json['verification_notes'] as String?, // String nulo

      // Campos int nulos
      resolvedBy: (json['resolved_by'] as num?)?.toInt(), // Casteo seguro para int nulo
      resolvedAt: json['resolved_at'] != null ? _parseDateTime(json['resolved_at']) : null,
      resolutionNotes: json['resolution_notes'] as String?, // String nulo
      comments: json['comments'] as String?, // String nulo (si es un string simple; si es un objeto o lista, se necesita más parsing)
    );
  }

  /// Método auxiliar para parsear valores de fecha dinámicos (String o List<int>) a DateTime.
  /// Devuelve null si el valor es null o no puede ser parseado.
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    // Si es una lista (por ejemplo, [año, mes, día, hora, minuto, segundo, nano])
    if (dateValue is List && dateValue.length >= 6) {
      try {
        return DateTime(
          dateValue[0] as int, // año
          dateValue[1] as int, // mes
          dateValue[2] as int, // día
          dateValue[3] as int, // hora
          dateValue[4] as int, // minuto
          dateValue[5] as int, // segundo
          (dateValue.length > 6 ? (dateValue[6] as int) ~/ 1000000 : 0), // milisegundos de nanosegundos
        );
      } catch (e) {
        print('[ReportResponseDto] Error parsing date from array: $dateValue -> $e');
        return null;
      }
    }

    // Si es un string ISO 8601
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('[ReportResponseDto] Error parsing date from string: $dateValue -> $e');
        return null;
      }
    }

    // Si no es ninguno de los anteriores, devuelve null
    return null;
  }

  /// Convierte el DTO a una entidad de dominio (ReportInfoEntity).
  ReportInfoEntity toDomainEntity() {
    return ReportInfoEntity(
      id: id.toString(),
      title: title,
      description: description,
      incident_type: incidentType,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reporterName: reporterName,
      reporterEmail: null, // Este campo no está en tu DTO ni en la respuesta del servidor
      severity: severity,
      isAnonymous: isAnonymous,
      // Considera añadir más campos si ReportInfoEntity los necesita
      // como status, imageUrl, audioUrl, createdAt, updatedAt, etc.
      // status: status,
      // imageUrl: imageUrl,
      // audioUrl: audioUrl,
      // createdAt: createdAt,
      // updatedAt: updatedAt,
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