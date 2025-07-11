import 'package:safy/report/domain/entities/report.dart';

class ReportRequestDto {

  final String title;
  final String userName;
  final String location;
  final String incidentType;
  final DateTime dateTime;
  final String description;

  const ReportRequestDto({
  
    required this.title,
    required this.userName,
    required this.location,
    required this.incidentType,
    required this.dateTime,
    required this.description,
  });

  factory ReportRequestDto.fromJson(Map<String, dynamic> json) {
    return ReportRequestDto(
      title: json['title'],
      userName: json['userName'],
      incidentType: json['incidentType'],
      location: json['location'],
      dateTime: DateTime.parse(json['dateTime']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'title': title,
      'userName': userName,
      'incidentType': incidentType,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
    };
  }

  ReportInfoEntity toDomainEntity() {
    return ReportInfoEntity(
 
      title: title,
      description: description,
      userName: userName,
      incidentType: incidentType,
      location: location,
      dateTime: dateTime,
    );
  }
}
