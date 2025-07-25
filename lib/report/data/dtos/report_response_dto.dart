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
  final int severity; // Assuming 'severity' is always guaranteed to be an int from the server in valid responses.
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

  /// Factory method to create a ReportResponseDto from a JSON map.
  /// It expects the report data to be nested under a 'data' key.
  factory ReportResponseDto.fromJson(Map<String, dynamic> json) {
    // Safely access the 'data' key, which contains the actual report details.
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;

    // If 'data' is null, or not a Map, this indicates a malformed response.
    if (data == null) {
      throw FormatException('La respuesta del servidor no contiene la clave "data" o está malformada.');
    }

    return ReportResponseDto(
      // Access fields from the 'data' map
      id: data['id'] as int,
      title: data['title'] as String,
      description: data['description'] as String,
      incidentType: data['incident_type'] as String,
      status: data['status'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] as String?, // Nullable string, use 'as String?'
      reporterName: data['reporter_name'] as String,
      isAnonymous: data['is_anonymous'] as bool,
      // Assuming 'severity' is always an int when present. If it can be null, change to 'as int?'
      severity: data['severity'] as int,
      imageUrl: data['image_url'] as String?, // Nullable string
      audioUrl: data['audio_url'] as String?, // Nullable string
      
      // Handle DateTime parsing, providing null if the value from JSON is null
      createdAt: data['created_at'] != null ? _parseDateTime(data['created_at']) : null,
      updatedAt: data['updated_at'] != null ? _parseDateTime(data['updated_at']) : null,
      
      // Nullable int fields
      verifiedBy: data['verified_by'] as int?,
      verifiedAt: data['verified_at'] != null ? _parseDateTime(data['verified_at']) : null,
      verificationNotes: data['verification_notes'] as String?, // Nullable string
      
      // Nullable int fields
      resolvedBy: data['resolved_by'] as int?,
      resolvedAt: data['resolved_at'] != null ? _parseDateTime(data['resolved_at']) : null,
      resolutionNotes: data['resolution_notes'] as String?, // Nullable string
      comments: data['comments'] as String?, // Nullable string
    );
  }

  /// Helper method to parse dynamic date values (String or List<int>) into DateTime.
  /// Returns null if the value is null or cannot be parsed.
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    // If it's a list (e.g., [year, month, day, hour, minute, second, nano])
    if (dateValue is List && dateValue.length >= 6) {
      try {
        return DateTime(
          dateValue[0], // year
          dateValue[1], // month
          dateValue[2], // day
          dateValue[3], // hour
          dateValue[4], // minute
          dateValue[5], // second
          (dateValue.length > 6 ? (dateValue[6] as int) ~/ 1000000 : 0), // milliseconds from nanos
        );
      } catch (e) {
        print('[ReportResponseDto] Error parsing date from array: $dateValue -> $e');
        return null;
      }
    }

    // If it's an ISO 8601 string
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('[ReportResponseDto] Error parsing date from string: $dateValue -> $e');
        return null;
      }
    }
    
    // If it's neither, return null
    return null;
  }

  /// Converts the DTO to a domain entity (ReportInfoEntity).
  ReportInfoEntity toDomainEntity() {
    return ReportInfoEntity(
      id: id.toString(),
      title: title,
      description: description,
      incident_type: incidentType, // Changed from incidentType to incident_type as per domain entity
      latitude: latitude,
      longitude: longitude,
      address: address,
      reporterName: reporterName,
      reporterEmail: null, // As per previous note, backend doesn't return email here
      severity: severity,
      isAnonymous: isAnonymous,
      // If ReportInfoEntity has a dateTime field, you'll need to decide which DateTime to use.
      // Example: dateTime: createdAt ?? DateTime.now(),
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