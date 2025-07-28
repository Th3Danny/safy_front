import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';

/// Mixin para gestión de reportes y zonas peligrosas
mixin ReportsMixin on ChangeNotifier {
  // Propiedades de reportes
  final List<Marker> _dangerMarkers = [];
  List<Marker> get dangerMarkers => _dangerMarkers;

  bool _showDangerZones = true;
  bool get showDangerZones => _showDangerZones;

  // Dependencias abstractas
  GetReportsForMapUseCase? get getReportsForMapUseCase;

  // Cargar zonas de peligro
  Future<void> loadDangerZones(
    LatLng currentLocation, {
    double zoom = 15.0,
  }) async {
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
        _createReportMarkers(reports, zoom: zoom);
      } else {
        print(
          '[ReportsMixin] ⚠️ GetReportsForMapUseCase no disponible, usando datos ficticios',
        );
        _loadFakeDangerZones();
      }
    } catch (e) {
      print('[ReportsMixin] ❌ Error cargando reportes: $e');
      _loadFakeDangerZones();
    }
  }

  void _createReportMarkers(
    List<ReportInfoEntity> reports, {
    double zoom = 15.0,
  }) {
    _dangerMarkers.clear();

    if (zoom < 12.0) {
      // No mostrar reportes si el zoom es muy bajo
      print(
        '[ReportsMixin] 🔍 Zoom demasiado alejado (<12), no se muestran reportes.',
      );
      return;
    }

    for (final report in reports) {
      final (color, icon) = _getReportStyle(
        report.incident_type,
        report.severity,
      );

      double markerSize = _getMarkerSize(report.severity) * _getZoomScale(zoom);
      if (markerSize < 8.0) markerSize = 8.0;

      _dangerMarkers.add(
        Marker(
          key: Key('report_${report.hashCode}'),
          point: LatLng(report.latitude, report.longitude),
          width: markerSize,
          height: markerSize,
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
                  Center(
                    child: Icon(icon, color: color, size: markerSize * 0.4),
                  ),
                  Positioned(
                    top: markerSize * 0.1,
                    right: markerSize * 0.1,
                    child: Container(
                      width: markerSize * 0.35,
                      height: markerSize * 0.35,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${report.severity}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: markerSize * 0.2,
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

    print(
      '[ReportsMixin] 🗺️ Creados ${_dangerMarkers.length} marcadores reales',
    );
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

  double _getZoomScale(double zoom) {
    // Zoom base 15.0, escala 1.0. Si alejas, reduce tamaño; si acercas, aumenta.
    return 1.0 / (1.0 + (15.0 - zoom) * 0.25).clamp(0.5, 2.0);
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
    try {
      // 🚨 NUEVO: Verificar contra datos reales de clusters de peligros
      final mapViewModel = GetIt.instance<MapViewModel>();
      final dangerousClusters = mapViewModel.clusters;

      if (dangerousClusters.isEmpty) {
        print(
          '[ReportsMixin] ⚠️ No hay datos de clusters de peligros disponibles',
        );
        return false;
      }

      for (final cluster in dangerousClusters) {
        final distance = Distance().as(
          LengthUnit.Meter,
          point,
          LatLng(cluster.centerLatitude, cluster.centerLongitude),
        );

        // Radio del cluster basado en la severidad y cantidad de reportes
        final clusterRadius = _calculateClusterRadius(cluster);

        if (distance <= clusterRadius) {
          print(
            '[ReportsMixin] ⚠️ Punto en zona peligrosa: ${point.latitude}, ${point.longitude} (distancia: ${distance.toInt()}m, radio: ${clusterRadius.toInt()}m)',
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      print('[ReportsMixin] ❌ Error verificando zona peligrosa: $e');
      return false;
    }
  }

  double calculateRouteSafety(List<LatLng> route) {
    if (route.isEmpty) return 100.0;

    double safetyScore = 100.0;
    int totalChecks = 0;
    int dangerousChecks = 0;

    // 🚨 SOLUCIÓN DRÁSTICA: Usar solo los puntos principales de la ruta
    final checkPoints = <LatLng>[];

    // Agregar solo puntos principales (cada 3 puntos para reducir drásticamente)
    for (int i = 0; i < route.length; i += 3) {
      checkPoints.add(route[i]);
    }

    // Asegurar que siempre tengamos al menos 2 puntos
    if (checkPoints.length < 2 && route.length >= 2) {
      checkPoints.add(route.last);
    }

    // 🚨 Verificar contra marcadores de peligro (datos reales)
    for (final point in checkPoints) {
      totalChecks++;
      bool isInDanger = false;

      // Verificar contra marcadores de peligro (datos reales)
      for (final dangerMarker in _dangerMarkers) {
        final distance = Distance().as(
          LengthUnit.Meter,
          point,
          dangerMarker.point,
        );

        // Penalización basada en distancia
        if (distance <= 50) {
          safetyScore -= 20; // Muy cerca de zona peligrosa
          dangerousChecks++;
          isInDanger = true;
          break; // Salir del bucle una vez que se encuentra peligro
        } else if (distance <= 100) {
          safetyScore -= 12; // Cerca de zona peligrosa
          isInDanger = true;
        } else if (distance <= 200) {
          safetyScore -= 6; // Moderadamente cerca
        } else if (distance <= 500) {
          safetyScore -= 2; // Levemente cerca
        }
      }

      if (isInDanger) {
        dangerousChecks++;
      }
    }

    // 🕐 Factor de hora del día
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 18) {
      safetyScore += 8; // Día: más seguro
    } else if (hour >= 19 && hour <= 22) {
      safetyScore -= 5; // Noche temprana: moderadamente peligroso
    } else {
      safetyScore -= 15; // Noche tardía: muy peligroso
    }

    // 📊 Factor de densidad de peligros
    if (totalChecks > 0) {
      final dangerPercentage = dangerousChecks / totalChecks;
      if (dangerPercentage > 0.4) {
        safetyScore -= 25; // Muchos puntos peligrosos
      } else if (dangerPercentage > 0.2) {
        safetyScore -= 15; // Algunos puntos peligrosos
      } else if (dangerPercentage > 0.1) {
        safetyScore -= 8; // Pocos puntos peligrosos
      }
    }

    // 🎯 Factor de longitud de ruta
    final routeLength = _calculateRouteLength(route);
    if (routeLength > 5000) {
      // Más de 5km
      safetyScore -= 5; // Rutas largas son más peligrosas
    }

    final finalScore = safetyScore.clamp(0.0, 100.0);

    // Solo imprimir una vez por ruta para evitar spam
    print(
      '[ReportsMixin] 📊 Seguridad calculada: ${finalScore.toInt()}% ($dangerousChecks/$totalChecks puntos peligrosos, ${route.length} puntos de ruta)',
    );

    return finalScore;
  }

  // 🎯 NUEVO: Calcular longitud total de la ruta
  double _calculateRouteLength(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalLength = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalLength += Distance().as(LengthUnit.Meter, route[i], route[i + 1]);
    }
    return totalLength;
  }

  // 🎯 NUEVO: Calcular radio del cluster basado en severidad y reportes
  double _calculateClusterRadius(ClusterEntity cluster) {
    // Radio base según severidad
    double baseRadius = 150.0; // Radio base en metros

    // Ajustar según severidad
    switch (cluster.severity.toUpperCase()) {
      case 'CRITICAL':
        baseRadius = 300.0;
        break;
      case 'HIGH':
        baseRadius = 250.0;
        break;
      case 'MEDIUM':
        baseRadius = 200.0;
        break;
      case 'LOW':
        baseRadius = 150.0;
        break;
      default:
        baseRadius = 200.0;
    }

    // Ajustar según cantidad de reportes
    if (cluster.reportCount > 10) {
      baseRadius += 100.0;
    } else if (cluster.reportCount > 5) {
      baseRadius += 50.0;
    }

    return baseRadius;
  }


  // Callbacks abstractos
  void onReportSelected(ReportInfoEntity report);
  void onDangerZonesToggled(bool visible);
}
