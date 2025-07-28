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

        // Calcular tamaño basado en reportes y severidad
        double baseSize = 40.0;
        double sizeMultiplier = 1.0;

        // Multiplicador por cantidad de reportes
        if (reportCount >= 10) sizeMultiplier += 0.5;
        if (reportCount >= 20) sizeMultiplier += 0.3;
        if (reportCount >= 30) sizeMultiplier += 0.2;

        // Multiplicador por severidad
        if (severity >= 4) sizeMultiplier += 0.4;
        if (severity >= 3) sizeMultiplier += 0.2;

        // Aplicar factor de zoom (simulado)
        final scaleFactor =
            1.0; // En implementación real, usarías el zoom actual
        final finalSize = (baseSize * sizeMultiplier * scaleFactor).clamp(
          20.0,
          80.0,
        );

        // Color según severidad
        Color clusterColor;
        if (severity >= 4) {
          clusterColor = Colors.red;
        } else if (severity >= 3) {
          clusterColor = Colors.orange;
        } else {
          clusterColor = Colors.yellow;
        }

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
                  color: clusterColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: (finalSize * 0.4).clamp(12.0, 24.0),
                    ),
                    Text(
                      '$reportCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: (finalSize * 0.25).clamp(8.0, 16.0),
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
}
