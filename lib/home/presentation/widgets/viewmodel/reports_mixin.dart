import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';


/// Mixin para gestión de reportes y zonas peligrosas
mixin ReportsMixin on ChangeNotifier {
  
  // Propiedades de reportes
  List<Marker> _dangerMarkers = [];
  List<Marker> get dangerMarkers => _dangerMarkers;

  bool _showDangerZones = true;
  bool get showDangerZones => _showDangerZones;

  // Dependencias abstractas
  GetReportsForMapUseCase? get getReportsForMapUseCase;

  // Cargar zonas de peligro
  Future<void> loadDangerZones(LatLng currentLocation) async {
    try {
      if (getReportsForMapUseCase != null) {
        final reports = await getReportsForMapUseCase!.execute(
          userId: "public",
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          page: 0,
          pageSize: 50,
        );

        print('[ReportsMixin] 📊 Cargados ${reports.length} reportes reales');
        _createReportMarkers(reports);
      } else {
        print('[ReportsMixin] ⚠️ GetReportsForMapUseCase no disponible, usando datos ficticios');
        _loadFakeDangerZones();
      }
    } catch (e) {
      print('[ReportsMixin] ❌ Error cargando reportes: $e');
      _loadFakeDangerZones();
    }
  }

  void _createReportMarkers(List<ReportInfoEntity> reports) {
    _dangerMarkers.clear();

    for (final report in reports) {
      final (color, icon) = _getReportStyle(report.incident_type, report.severity);

      _dangerMarkers.add(
        Marker(
          key: Key('report_${report.hashCode}'),
          point: LatLng(report.latitude, report.longitude),
          width: _getMarkerSize(report.severity),
          height: _getMarkerSize(report.severity),
          child: GestureDetector(
            onTap: () => _onReportTapped(report),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icon, color: color, size: 20)),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${report.severity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    print('[ReportsMixin] 🗺️ Creados ${_dangerMarkers.length} marcadores reales');
  }

  (Color, IconData) _getReportStyle(String incidentType, int severity) {
    IconData icon;
    switch (incidentType) {
      case 'STREET_HARASSMENT':
        icon = Icons.report_problem;
        break;
      case 'ROBBERY_ASSAULT':
        icon = Icons.security;
        break;
      case 'KIDNAPPING':
        icon = Icons.warning_amber;
        break;
      case 'GANG_VIOLENCE':
        icon = Icons.groups;
        break;
      default:
        icon = Icons.info;
    }

    Color color;
    if (severity >= 4) {
      color = Colors.red;
    } else if (severity >= 2) {
      color = Colors.orange;
    } else {
      color = Colors.yellow[700]!;
    }

    return (color, icon);
  }

  double _getMarkerSize(int severity) {
    if (severity >= 4) return 50;
    if (severity >= 2) return 40;
    return 35;
  }

  void _onReportTapped(ReportInfoEntity report) {
    print('[ReportsMixin] 📍 Reporte seleccionado: ${report.title}');
    onReportSelected(report);
  }

  void _loadFakeDangerZones() {
    // Datos ficticios para desarrollo
    _dangerMarkers.clear();
    
    final fakeDangers = [
      (16.7580, -93.1300, Colors.red, 4),
      (16.7520, -93.1280, Colors.orange, 3),
      (16.7600, -93.1350, Colors.red, 5),
    ];

    for (int i = 0; i < fakeDangers.length; i++) {
      final danger = fakeDangers[i];
      _dangerMarkers.add(
        Marker(
          key: Key('fake_danger_$i'),
          point: LatLng(danger.$1, danger.$2),
          width: _getMarkerSize(danger.$4),
          height: _getMarkerSize(danger.$4),
          child: Container(
            decoration: BoxDecoration(
              color: danger.$3.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: danger.$3, width: 3),
            ),
            child: Icon(Icons.warning, color: danger.$3, size: 20),
          ),
        ),
      );
    }
  }

  void toggleDangerZones() {
    _showDangerZones = !_showDangerZones;
    onDangerZonesToggled(_showDangerZones);
    notifyListeners();
  }

  bool isPointInDangerZone(LatLng point) {
    const dangerRadius = 100.0;

    for (final dangerMarker in _dangerMarkers) {
      final distance = Distance().as(LengthUnit.Meter, point, dangerMarker.point);
      if (distance <= dangerRadius) {
        return true;
      }
    }
    return false;
  }

  double calculateRouteSafety(List<LatLng> route) {
    if (route.isEmpty) return 100.0;

    double safetyScore = 100.0;
    int totalChecks = 0;
    int dangerousChecks = 0;

    final checkPoints = <LatLng>[];
    checkPoints.addAll(route);

    for (int i = 0; i < route.length - 1; i++) {
      final intermediatePoints = _getPointsAlongPath(route[i], route[i + 1], intervalMeters: 50);
      checkPoints.addAll(intermediatePoints);
    }

    for (final point in checkPoints) {
      totalChecks++;
      bool isInDanger = false;

      for (final dangerMarker in _dangerMarkers) {
        final distance = Distance().as(LengthUnit.Meter, point, dangerMarker.point);

        if (distance <= 50) {
          safetyScore -= 15;
          dangerousChecks++;
          isInDanger = true;
        } else if (distance <= 100) {
          safetyScore -= 8;
          isInDanger = true;
        } else if (distance <= 200) {
          safetyScore -= 3;
        }
      }

      if (isInDanger) {
        dangerousChecks++;
      }
    }

    if (totalChecks > 0) {
      final dangerPercentage = dangerousChecks / totalChecks;
      if (dangerPercentage > 0.3) {
        safetyScore -= 20;
      }
    }

    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 18) {
      safetyScore += 5;
    } else {
      safetyScore -= 10;
    }

    final finalScore = safetyScore.clamp(0.0, 100.0);

    print('[ReportsMixin] 📊 Seguridad calculada: ${finalScore.toInt()}% (${dangerousChecks}/${totalChecks} puntos peligrosos)');

    return finalScore;
  }

  List<LatLng> _getPointsAlongPath(LatLng start, LatLng end, {double intervalMeters = 50}) {
    final points = <LatLng>[];
    final totalDistance = Distance().as(LengthUnit.Meter, start, end);

    if (totalDistance < intervalMeters) {
      return [];
    }

    final numPoints = (totalDistance / intervalMeters).ceil();

    for (int i = 1; i < numPoints; i++) {
      final fraction = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  // Callbacks abstractos
  void onReportSelected(ReportInfoEntity report);
  void onDangerZonesToggled(bool visible);
}