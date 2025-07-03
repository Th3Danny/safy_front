
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/value_objects/danger_level.dart';

class DangerZone {
  final String id;
  final Location center;
  final double radiusMeters;
  final DangerLevel dangerLevel;
  final int reportCount;
  final DateTime lastReportAt;
  final List<String> incidentTypes;
  final bool isActive;

  DangerZone({
    required this.id,
    required this.center,
    required this.radiusMeters,
    required this.dangerLevel,
    required this.reportCount,
    required this.lastReportAt,
    required this.incidentTypes,
    this.isActive = true,
  });

  // Métodos de negocio
  bool isLocationInDangerZone(Location location) {
    final distance = _calculateDistance(center, location);
    return distance <= radiusMeters;
  }

  bool get isRecent => DateTime.now().difference(lastReportAt).inHours <= 24;

  double _calculateDistance(Location point1, Location point2) {
    // Implementar cálculo de distancia usando la fórmula de Haversine
    const double earthRadius = 6371000; // metros
    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159 / 180);

    final double a = (deltaLatRad / 2).abs() * (deltaLatRad / 2).abs() +
        lat1Rad.abs() * lat2Rad.abs() * (deltaLngRad / 2).abs() * (deltaLngRad / 2).abs();
    final double c = 2 * (a.abs().clamp(0, 1));
    
    return earthRadius * c;
  }
}