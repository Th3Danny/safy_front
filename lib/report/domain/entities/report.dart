class ReportInfoEntity {
 
  final String title;
  final String userName;
  final String location;
  final String incidentType;
  final DateTime dateTime;
  final String description;

  ReportInfoEntity({
   
    required this.title,
    required this.userName,
    required this.location,
    required this.incidentType,
    required this.dateTime,
    required this.description,
  });

  @override
  String toString() {
    return 'ReportInfoEntity( title: $title, userName: $userName, location: $location, incidentType: $incidentType, dateTime: $dateTime, description: $description)';
  }

  String get formattedDate =>
      '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  String get shortTitle =>
      title.length > 20 ? '${title.substring(0, 20)}...' : title;

  String get shortDescription =>
      description.length > 50 ? '${description.substring(0, 50)}...' : description;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is ReportInfoEntity);
  }

  
}
