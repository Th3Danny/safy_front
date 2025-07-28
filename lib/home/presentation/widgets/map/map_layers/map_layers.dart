import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class MapLayers {
  static TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiZ2Vyc29uMjIiLCJhIjoiY21kbWptYmlzMXE4bzJsb2pyaWgwOHNjayJ9.Fz4sLUzyNfo95LZa0ITtkA',
      userAgentPackageName: 'com.example.safy',
      maxZoom: 18,
    );
  }

  static MarkerLayer buildMarkerLayer(MapViewModel mapViewModel) {
    return MarkerLayer(
      markers: [
        // Marcador de ubicación actual
        Marker(
          point: mapViewModel.currentLocation,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  static PolylineLayer buildPolylineLayer(MapViewModel mapViewModel) {
    if (mapViewModel.currentRoute.isEmpty) {
      return const PolylineLayer(polylines: []);
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: mapViewModel.currentRoute,
          strokeWidth: 4,
          color: Colors.blue,
        ),
      ],
    );
  }

  static MarkerLayer buildClusterLayer(
    MapViewModel mapViewModel, [
    BuildContext? context,
  ]) {
    final markers = <Marker>[];

    if (mapViewModel.showClusters && mapViewModel.clusters.isNotEmpty) {
      for (final cluster in mapViewModel.clusters) {
        final severity = cluster.severityNumber ?? 1;
        final reportCount = cluster.reportCount ?? 0;

        // 🎯 NUEVA LÓGICA: Tamaño dinámico basado en reportes y severidad
        double baseSize = 30.0; // Tamaño base más pequeño

        // Factor de tamaño por cantidad de reportes (más reportes = más grande)
        double reportMultiplier = 1.0;
        if (reportCount >= 5) reportMultiplier += 0.3;
        if (reportCount >= 10) reportMultiplier += 0.4;
        if (reportCount >= 15) reportMultiplier += 0.5;
        if (reportCount >= 20) reportMultiplier += 0.6;
        if (reportCount >= 25) reportMultiplier += 0.7;
        if (reportCount >= 30) reportMultiplier += 0.8;

        // Factor de tamaño por severidad (más severidad = más grande)
        double severityMultiplier = 1.0;
        if (severity >= 1)
          severityMultiplier += 0.1; // Severidad 1 - pequeño incremento
        if (severity >= 2) severityMultiplier += 0.2;
        if (severity >= 3) severityMultiplier += 0.3;
        if (severity >= 4) severityMultiplier += 0.4;
        if (severity >= 5) severityMultiplier += 0.5;

        // Combinar multiplicadores
        double totalMultiplier = reportMultiplier * severityMultiplier;

        // Aplicar factor de zoom (simulado)
        final scaleFactor = 1.0;
        final finalSize = (baseSize * totalMultiplier * scaleFactor).clamp(
          25.0, // Mínimo más grande
          120.0, // Máximo más grande
        );

        // 🎨 NUEVA LÓGICA: Color dinámico basado en severidad y reportes
        Color clusterColor;
        double colorIntensity = 0.6; // Intensidad base

        // Aumentar intensidad por severidad
        if (severity >= 5) {
          clusterColor = Colors.red;
          colorIntensity = 1.0;
        } else if (severity >= 4) {
          clusterColor = Colors.red;
          colorIntensity = 0.9;
        } else if (severity >= 3) {
          clusterColor = Colors.orange;
          colorIntensity = 0.8;
        } else if (severity >= 2) {
          clusterColor = Colors.yellow;
          colorIntensity = 0.7;
        } else {
          // Severidad 1 - verde claro para indicar peligro bajo
          clusterColor = Colors.green;
          colorIntensity = 0.6;
        }

        // Aumentar intensidad por cantidad de reportes
        if (reportCount >= 10) colorIntensity += 0.1;
        if (reportCount >= 20) colorIntensity += 0.1;
        if (reportCount >= 30) colorIntensity += 0.1;

        // Aplicar intensidad al color
        final adjustedColor = clusterColor.withOpacity(
          colorIntensity.clamp(0.6, 1.0),
        );

        // 🎯 NUEVO: Radio dinámico basado en reportes
        double clusterRadius = 50.0; // Radio base
        if (reportCount >= 5) clusterRadius += 20;
        if (reportCount >= 10) clusterRadius += 30;
        if (reportCount >= 15) clusterRadius += 40;
        if (reportCount >= 20) clusterRadius += 50;
        if (reportCount >= 25) clusterRadius += 60;
        if (reportCount >= 30) clusterRadius += 70;

        // Ajustar radio por severidad
        if (severity >= 1) clusterRadius += 5; // Severidad 1 - radio pequeño
        if (severity >= 2) clusterRadius += 10;
        if (severity >= 3) clusterRadius += 20;
        if (severity >= 4) clusterRadius += 30;
        if (severity >= 5) clusterRadius += 40;

        // 📊 Logs para debugging
        print(
          '🎯 [MapLayers] Cluster: ${cluster.centerLatitude.toStringAsFixed(4)}, ${cluster.centerLongitude.toStringAsFixed(4)}',
        );
        print('   📍 Reportes: $reportCount, Severidad: $severity');
        print(
          '   📏 Tamaño: ${finalSize.toStringAsFixed(1)}px (Base: $baseSize, Report: ${reportMultiplier.toStringAsFixed(2)}, Severidad: ${severityMultiplier.toStringAsFixed(2)})',
        );
        print(
          '   🎨 Color: ${clusterColor.toString()}, Intensidad: ${colorIntensity.toStringAsFixed(2)}',
        );
        print('   🔴 Radio: ${clusterRadius.toStringAsFixed(0)}m');

        markers.add(
          Marker(
            point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
            width: finalSize,
            height: finalSize,
            child: GestureDetector(
              onTap: () {
                if (context != null) {
                  _showClusterInfo(context, cluster);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: adjustedColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: (finalSize * 0.08).clamp(
                      2.0,
                      6.0,
                    ), // Borde proporcional
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: adjustedColor.withOpacity(0.4),
                      blurRadius: (finalSize * 0.3).clamp(8.0, 20.0),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono dinámico basado en severidad
                    Icon(
                      severity >= 5
                          ? Icons.dangerous
                          : severity >= 4
                          ? Icons.dangerous
                          : severity >= 3
                          ? Icons.warning
                          : severity >= 2
                          ? Icons.info
                          : Icons.location_on,
                      color: Colors.white,
                      size: (finalSize * 0.4).clamp(12.0, 28.0),
                    ),
                    // Texto con tamaño dinámico
                    Text(
                      '$reportCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: (finalSize * 0.25).clamp(8.0, 18.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  static void _showClusterInfo(BuildContext context, dynamic cluster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador visual
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Zona de Riesgo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información del cluster
                _buildInfoRow(
                  'Tipo de Incidente',
                  cluster.dominantIncidentName ?? 'N/A',
                ),
                _buildInfoRow('Reportes', '${cluster.reportCount ?? 0}'),
                _buildInfoRow('Severidad', '${cluster.severityNumber ?? 0}/5'),
                _buildInfoRow('Zona', cluster.zone ?? 'N/A'),
                _buildInfoRow(
                  'Distancia',
                  '${(cluster.distanceFromUser ?? 0).toStringAsFixed(2)} km',
                ),

                const SizedBox(height: 16),

                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 NUEVO: Capa de marcadores de predicciones
  static MarkerLayer buildPredictionLayer(MapViewModel mapViewModel) {
    final markers = <Marker>[];

    if (mapViewModel.showPredictions && mapViewModel.predictions.isNotEmpty) {
      print(
        '[MapLayers] 🔮 Construyendo capa de predicciones con ${mapViewModel.predictions.length} predicciones',
      );

      for (final prediction in mapViewModel.predictions) {
        // 🟡 PREDICCIONES EN COLOR AMARILLO
        final marker = Marker(
          point: LatLng(
            prediction.location.latitude,
            prediction.location.longitude,
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              print(
                '[MapLayers] 🔮 Predicción seleccionada: ${prediction.riskLevel}',
              );
              // Aquí podrías mostrar información de la predicción
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(
                  0.8,
                ), // 🟡 Color amarillo para predicciones
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology, // Icono de predicción
                color: Colors.orange[800],
                size: 25,
              ),
            ),
          ),
        );

        markers.add(marker);
        print(
          '[MapLayers] 🔮 Marcador de predicción agregado: ${prediction.location.latitude}, ${prediction.location.longitude}',
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  // 🆕 NUEVO: Capa de todos los marcadores del mapa
  static MarkerLayer buildAllMarkersLayer(MapViewModel mapViewModel) {
    print('[MapLayers] 🎯 Construyendo capa de todos los marcadores');
    print(
      '[MapLayers] 📍 Marcadores totales: ${mapViewModel.allMapMarkers.length}',
    );

    return MarkerLayer(markers: mapViewModel.allMapMarkers);
  }
}
