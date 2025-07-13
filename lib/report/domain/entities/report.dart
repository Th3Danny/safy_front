class ReportInfoEntity {
  final String title;
  final String description;
  final String incident_type;
  final double latitude;
  final double longitude;
  final String? address;
  final String reporterName;
  final String? reporterEmail;
  final int severity;
  final bool isAnonymous;
  //final DateTime dateTime;

  ReportInfoEntity({
    required this.title,
    required this.description,
    required this.incident_type,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.reporterName,
    this.reporterEmail,
    required this.severity,
    required this.isAnonymous,
    //required this.dateTime,
  });

  @override
  String toString() {
    return 'ReportInfoEntity('
        'title: $title, '
        'description: $description, '
        'incident_type: $incident_type, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'address: $address, '
        'reporterName: $reporterName, '
        'reporterEmail: $reporterEmail, '
        'severity: $severity, '
        'isAnonymous: $isAnonymous, '
        //'dateTime: $dateTime'
        ')';
  }

  // String get formattedDate =>
  //     '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  String get shortTitle =>
      title.length > 20 ? '${title.substring(0, 20)}...' : title;

  String get shortDescription =>
      description.length > 50 ? '${description.substring(0, 50)}...' : description;

  String get coordinates => '$latitude, $longitude';

  String get severityText {
    switch (severity) {
      case 1:
        return 'Bajo';
      case 2:
        return 'Medio-Bajo';
      case 3:
        return 'Medio';
      case 4:
        return 'Alto';
      case 5:
        return 'Crítico';
      default:
        return 'Desconocido';
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReportInfoEntity &&
            title == other.title &&
            latitude == other.latitude &&
            longitude == other.longitude); //&&
            //dateTime == other.dateTime
  }

  @override
  int get hashCode => Object.hash(title, latitude, longitude); //, dateTime);
}