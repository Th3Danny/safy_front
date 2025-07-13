import 'package:safy/report/domain/entities/report.dart';

class ReportRequestDto {
  final String title;
  final String description;
  final String incident_type;
  final double latitude;
  final double longitude;
  final String? address;
  final String reporter_name;
  final String? reporter_email;
  final int severity;
  final bool is_anonymous;
  //final DateTime dateTime;

  const ReportRequestDto({
    required this.title,
    required this.description,
    required this.incident_type,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.reporter_name,
    this.reporter_email,
    required this.severity,
    required this.is_anonymous,
   // required this.dateTime,
  });

  factory ReportRequestDto.fromJson(Map<String, dynamic> json) {
    return ReportRequestDto(
      title: json['title'],
      description: json['description'],
      incident_type: json['incident_type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      reporter_name: json['reporter_name'],
      reporter_email: json['reporter_email'],
      severity: json['severity'],
      is_anonymous: json['is_anonymous'],
      //dateTime: DateTime.parse(json['dateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'incident_type': incident_type,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reporter_name': reporter_name,
      'reporter_email': reporter_email,
      'severity': severity,
      'is_anonymous': is_anonymous,
      //'dateTime': dateTime.toIso8601String(),
    };
  }

  ReportInfoEntity toDomainEntity() {
    return ReportInfoEntity(
      title: title,
      description: description,
      incident_type: incident_type,
      latitude: latitude,
      longitude: longitude,
      address: address,
      reporterName: reporter_name,
      reporterEmail: reporter_email,
      severity: severity,
      isAnonymous: is_anonymous,
      //dateTime: dateTime,
    );
  }
}