// lib/features/home/presentation/widgets/viewmodel/clusters_mixin.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';
import 'package:safy/report/domain/usecases/get_clusters_use_case.dart';
import 'dart:math' as math;

/// Mixin para gestión de clusters de zonas peligrosas
mixin ClustersMixin on ChangeNotifier {
  // Propiedades de clusters
  final List<Marker> _clusterMarkers = [];
  List<Marker> get clusterMarkers => _clusterMarkers;

  bool _showClusters = true;
  bool get showClusters => _showClusters;

  List<ClusterEntity> _clusters = [];
  List<ClusterEntity> get clusters => _clusters;

  bool _clustersLoading = false;
  bool get clustersLoading => _clustersLoading;

  String? _clustersError;
  String? get clustersError => _clustersError;

  // Dependencia del caso de uso - debe ser implementado por el ViewModel
  GetClustersUseCase? get getClustersUseCase;

  // Cargar clusters de zonas peligrosas
  Future<void> loadDangerousClusters(
    LatLng currentLocation, {
    double zoom = 15.0,
  }) async {
    if (_clustersLoading) return; // Evitar cargas múltiples

    _clustersLoading = true;
    _clustersError = null;
    notifyListeners();

    try {
      print(
        '[ClustersMixin] 📍 Cargando clusters de zonas peligrosas cerca de: ${currentLocation.latitude}, ${currentLocation.longitude}',
      );

      if (getClustersUseCase != null) {
        _clusters = await getClustersUseCase!.execute(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );

        print(
          '[ClustersMixin] 📊 Cargados ${_clusters.length} clusters desde API',
        );

        if (_clusters.isNotEmpty) {
          _createClusterMarkers(_clusters, zoom: zoom);
          print(
            '[ClustersMixin] ✅ Marcadores de clusters creados exitosamente',
          );
        } else {
          print('[ClustersMixin] ℹ️ No hay clusters cercanos');
          _clusterMarkers.clear();
        }
      } else {
        print(
          '[ClustersMixin] ⚠️ GetClustersUseCase no disponible, usando datos ficticios',
        );
        _loadFakeClusters();
      }
    } catch (e) {
      print('[ClustersMixin] ❌ Error cargando clusters: $e');
      _clustersError = 'Error cargando zonas peligrosas: $e';
      print('[ClustersMixin] 🔄 Fallback a datos ficticios');
      _loadFakeClusters();
    } finally {
      _clustersLoading = false;
      notifyListeners();
    }
  }

  /// Carga clusters para un área específica de la vista del mapa
  Future<void> loadClustersForMapView(
    LatLng mapCenter, {
    double zoom = 15.0,
    double radiusKm = 5.0, // Radio de búsqueda en km
  }) async {
    print('[ClustersMixin] 🚀 loadClustersForMapView iniciado');

    if (_clustersLoading) {
      print('[ClustersMixin] ⏳ Ya se están cargando clusters, saltando...');
      return; // Evitar cargas múltiples
    }

    print(
      '[ClustersMixin] 📍 Cargando clusters para: ${mapCenter.latitude}, ${mapCenter.longitude} (radio: ${radiusKm}km)',
    );
    _clustersLoading = true;
    _clustersError = null;
    notifyListeners();

    try {
      print(
        '[ClustersMixin] 🗺️ Cargando clusters para vista del mapa: ${mapCenter.latitude}, ${mapCenter.longitude} (radio: ${radiusKm}km)',
      );

      if (getClustersUseCase != null) {
        // Usar el mismo caso de uso pero con el centro del mapa
        _clusters = await getClustersUseCase!.execute(
          latitude: mapCenter.latitude,
          longitude: mapCenter.longitude,
        );

        // Filtrar clusters que estén dentro del radio de la vista
        _clusters =
            _clusters.where((cluster) {
              final distance = _calculateDistance(
                mapCenter.latitude,
                mapCenter.longitude,
                cluster.centerLatitude,
                cluster.centerLongitude,
              );
              return distance <= radiusKm;
            }).toList();

        print(
          '[ClustersMixin] 📊 Cargados ${_clusters.length} clusters para vista del mapa',
        );

        if (_clusters.isNotEmpty) {
          _createClusterMarkers(_clusters, zoom: zoom);
          print(
            '[ClustersMixin] ✅ Marcadores de clusters creados para vista del mapa',
          );
        } else {
          print('[ClustersMixin] ℹ️ No hay clusters en esta área del mapa');
          _clusterMarkers.clear();
        }
      } else {
        print(
          '[ClustersMixin] ⚠️ GetClustersUseCase no disponible, usando datos ficticios',
        );
        _loadFakeClustersForMapView(mapCenter, radiusKm);
      }
    } catch (e) {
      print('[ClustersMixin] ❌ Error cargando clusters para vista: $e');
      _clustersError = 'Error cargando zonas peligrosas: $e';
      print('[ClustersMixin] 🔄 Fallback a datos ficticios');
      _loadFakeClustersForMapView(mapCenter, radiusKm);
    } finally {
      _clustersLoading = false;
      print('[ClustersMixin] ✅ loadClustersForMapView completado');
      notifyListeners();
    }
  }

  /// Calcula distancia entre dos puntos usando fórmula de Haversine
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convierte grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _createClusterMarkers(
    List<ClusterEntity> clusters, {
    double zoom = 15.0,
  }) {
    _clusterMarkers.clear();

    if (zoom < 12.0) {
      // No mostrar clusters si el zoom es muy bajo
      print(
        '[ClustersMixin] 🔍 Zoom demasiado alejado (<12), no se muestran clusters.',
      );
      return;
    }

    for (final cluster in clusters) {
      final (color, icon) = _getClusterStyle(
        cluster.dominantIncidentType,
        cluster.severityNumber,
      );

      // Escalado según zoom, tamaño mínimo 8
      double clusterSize =
          _getClusterSizeByReports(cluster.reportCount) * _getZoomScale(zoom);
      if (clusterSize < 8.0) clusterSize = 8.0;

      _clusterMarkers.add(
        Marker(
          key: Key('cluster_${cluster.clusterId}'),
          point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
          width: clusterSize,
          height: clusterSize,
          child: GestureDetector(
            onTap: () => _onClusterTapped(cluster),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(icon, color: color, size: clusterSize * 0.4),
                  ),
                  Positioned(
                    top: clusterSize * 0.05,
                    right: clusterSize * 0.05,
                    child: Container(
                      width: clusterSize * 0.35,
                      height: clusterSize * 0.35,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${cluster.severityNumber}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: clusterSize * 0.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: clusterSize * 0.05,
                    left: clusterSize * 0.05,
                    child: Container(
                      width: clusterSize * 0.32,
                      height: clusterSize * 0.32,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${cluster.reportCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: clusterSize * 0.18,
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
      '[ClustersMixin] 🗺️ Creados ${_clusterMarkers.length} marcadores de clusters',
    );
  }

  // ✅ NUEVO: Función que calcula tamaño fijo basado en número de reportes
  double _getClusterSizeByReports(int reportCount) {
    // Tamaños fijos basados en cantidad de reportes
    if (reportCount >= 20) return 70.0; // Zona MUY peligrosa
    if (reportCount >= 15) return 65.0; // Zona alta actividad
    if (reportCount >= 10) return 60.0; // Zona actividad moderada-alta
    if (reportCount >= 5) return 55.0; // Zona actividad moderada
    if (reportCount >= 3) return 50.0; // Zona actividad baja-moderada
    return 45.0; // Zona actividad mínima
  }

  double _getZoomScale(double zoom) {
    // Zoom base 15.0, escala 1.0. Si alejas, reduce tamaño; si acercas, aumenta.
    return 1.0 / (1.0 + (15.0 - zoom) * 0.25).clamp(0.5, 2.0);
  }

  (Color, IconData) _getClusterStyle(String incidentType, int severity) {
    // Icono basado en tipo de incidente dominante
    IconData icon;
    switch (incidentType.toUpperCase()) {
      case 'STREET_HARASSMENT':
      case 'ACOSO_CALLEJERO':
        icon = Icons.report_problem;
        break;
      case 'ROBBERY_ASSAULT':
      case 'ASALTOS':
      case 'ROBOS':
        icon = Icons.security;
        break;
      case 'KIDNAPPING':
      case 'SECUESTRO':
        icon = Icons.warning_amber;
        break;
      case 'GANG_VIOLENCE':
      case 'PANDILLAS':
        icon = Icons.groups;
        break;
      case 'PELEAS':
        icon = Icons.sports_mma;
        break;
      default:
        icon = Icons.dangerous;
    }

    // Color basado en severidad
    Color color;
    if (severity >= 5) {
      color = Colors.red[700]!;
    } else if (severity >= 4) {
      color = Colors.red[500]!;
    } else if (severity >= 3) {
      color = Colors.orange[600]!;
    } else {
      color = Colors.yellow[700]!;
    }

    return (color, icon);
  }

  double _getClusterMarkerSize(int severity) {
    // Los clusters son más grandes que reportes individuales
    if (severity >= 5) return 70;
    if (severity >= 4) return 60;
    if (severity >= 3) return 50;
    return 45;
  }

  void _onClusterTapped(ClusterEntity cluster) {
    print('[ClustersMixin] 📍 Cluster de zona peligrosa seleccionado:');
    print('[ClustersMixin] 🏷️ Tipo: ${cluster.dominantIncidentName}');
    print('[ClustersMixin] 📊 Reportes: ${cluster.reportCount}');
    print('[ClustersMixin] ⚠️ Severidad: ${cluster.severity}');
    print('[ClustersMixin] 🌍 Zona: ${cluster.zone}');
    print('[ClustersMixin] 📝 Descripción: ${cluster.description}');

    onClusterSelected(cluster);
  }

  void _loadFakeClusters() {
    // Datos ficticios para desarrollo/testing
    _clusterMarkers.clear();

    final fakeClusters = [
      (16.7580, -93.1300, Colors.red, 5, 'ROBBERY_ASSAULT', 'Asaltos/Robos', 3),
      (
        16.7520,
        -93.1280,
        Colors.orange,
        3,
        'STREET_HARASSMENT',
        'Acoso Callejero',
        2,
      ),
      (
        16.7600,
        -93.1350,
        Colors.red,
        4,
        'GANG_VIOLENCE',
        'Violencia Pandillas',
        4,
      ),
    ];

    for (int i = 0; i < fakeClusters.length; i++) {
      final cluster = fakeClusters[i];
      _clusterMarkers.add(
        Marker(
          key: Key('fake_cluster_$i'),
          point: LatLng(cluster.$1, cluster.$2),
          width:
              _getClusterMarkerSize(cluster.$4) *
              _getZoomScale(15.0), // Use _getZoomScale for fake data
          height:
              _getClusterMarkerSize(cluster.$4) *
              _getZoomScale(15.0), // Use _getZoomScale for fake data
          child: Container(
            decoration: BoxDecoration(
              color: cluster.$3.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: cluster.$3, width: 4),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.dangerous, color: cluster.$3, size: 28),
                ),
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${cluster.$7}',
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
      );
    }

    print(
      '[ClustersMixin] 🗺️ Creados ${_clusterMarkers.length} marcadores de clusters ficticios',
    );
  }

  /// Carga clusters ficticios para un área específica de la vista del mapa
  void _loadFakeClustersForMapView(LatLng mapCenter, double radiusKm) {
    _clusterMarkers.clear();

    // Generar clusters ficticios alrededor del centro del mapa
    final fakeClusters = [
      (
        mapCenter.latitude + 0.001,
        mapCenter.longitude + 0.001,
        Colors.red,
        5,
        'ROBBERY_ASSAULT',
        'Asaltos/Robos',
        3,
      ),
      (
        mapCenter.latitude - 0.002,
        mapCenter.longitude + 0.002,
        Colors.orange,
        3,
        'STREET_HARASSMENT',
        'Acoso Callejero',
        2,
      ),
      (
        mapCenter.latitude + 0.003,
        mapCenter.longitude - 0.001,
        Colors.red,
        4,
        'GANG_VIOLENCE',
        'Violencia Pandillas',
        4,
      ),
      (
        mapCenter.latitude - 0.001,
        mapCenter.longitude - 0.002,
        Colors.yellow,
        2,
        'THEFT',
        'Robos Menores',
        1,
      ),
      (
        mapCenter.latitude + 0.002,
        mapCenter.longitude + 0.003,
        Colors.orange,
        3,
        'DRUG_ACTIVITY',
        'Actividad de Drogas',
        2,
      ),
    ];

    for (int i = 0; i < fakeClusters.length; i++) {
      final cluster = fakeClusters[i];
      final clusterPoint = LatLng(cluster.$1, cluster.$2);

      // Verificar si el cluster está dentro del radio especificado
      final distance = _calculateDistance(
        mapCenter.latitude,
        mapCenter.longitude,
        clusterPoint.latitude,
        clusterPoint.longitude,
      );

      if (distance <= radiusKm) {
        _clusterMarkers.add(
          Marker(
            key: Key('fake_cluster_view_$i'),
            point: clusterPoint,
            width: _getClusterMarkerSize(cluster.$4) * _getZoomScale(15.0),
            height: _getClusterMarkerSize(cluster.$4) * _getZoomScale(15.0),
            child: Container(
              decoration: BoxDecoration(
                color: cluster.$3.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: cluster.$3, width: 4),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.dangerous, color: cluster.$3, size: 28),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${cluster.$7}',
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
        );
      }
    }

    print(
      '[ClustersMixin] 🗺️ Creados ${_clusterMarkers.length} marcadores de clusters ficticios para vista del mapa',
    );
  }

  void toggleClusters() {
    _showClusters = !_showClusters;
    onClustersToggled(_showClusters);
    notifyListeners();
  }

  bool isPointInDangerousCluster(LatLng point) {
    const dangerRadius = 150.0; // metros

    for (final cluster in _clusters) {
      final clusterPoint = LatLng(
        cluster.centerLatitude,
        cluster.centerLongitude,
      );
      final distance = Distance().as(LengthUnit.Meter, point, clusterPoint);
      if (distance <= dangerRadius && cluster.severityNumber >= 4) {
        return true;
      }
    }
    return false;
  }

  // Obtener información de seguridad de la zona
  String getZoneSafetyInfo(LatLng point) {
    for (final cluster in _clusters) {
      final clusterPoint = LatLng(
        cluster.centerLatitude,
        cluster.centerLongitude,
      );
      final distance = Distance().as(LengthUnit.Meter, point, clusterPoint);

      if (distance <= 200) {
        return '⚠️ Zona ${cluster.severity.toLowerCase()}: ${cluster.dominantIncidentName} (${cluster.reportCount} reportes)';
      }
    }
    return '✅ Zona sin alertas recientes';
  }

  // Limpiar clusters cuando sea necesario
  void clearClusters() {
    _clusters.clear();
    _clusterMarkers.clear();
    _clustersError = null;
    notifyListeners();
  }

  // Callbacks abstractos
  void onClusterSelected(ClusterEntity cluster);
  void onClustersToggled(bool visible);
}
