import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';

/// Widget para mostrar zonas de peligro en el mapa
/// con radios calculados basándose en la severidad de los incidentes
class DangerZoneOverlay extends StatelessWidget {
  final List<ClusterEntity> clusters;
  final bool showZones;
  final Function(ClusterEntity)? onZoneTap;

  const DangerZoneOverlay({
    super.key,
    required this.clusters,
    this.showZones = true,
    this.onZoneTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!showZones || clusters.isEmpty) {
      return const SizedBox.shrink();
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _calculateMapCenter(),
        initialZoom: 13.0,
        onTap: (_, point) {
          // Manejar tap en el mapa
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        // Capa de zonas de peligro
        CircleLayer(
          circles: _buildDangerZones(),
        ),
        // Capa de marcadores de clusters
        MarkerLayer(
          markers: _buildClusterMarkers(),
        ),
      ],
    );
  }

  /// Calcula el centro del mapa basándose en los clusters
  LatLng _calculateMapCenter() {
    if (clusters.isEmpty) {
      return const LatLng(16.720175, -93.008532); // Coordenadas por defecto
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final cluster in clusters) {
      totalLat += cluster.centerLatitude;
      totalLng += cluster.centerLongitude;
    }

    return LatLng(
      totalLat / clusters.length,
      totalLng / clusters.length,
    );
  }

  /// Construye las zonas de peligro como círculos
  List<CircleMarker> _buildDangerZones() {
    return clusters.map((cluster) {
      return CircleMarker(
        point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
        radius: cluster.calculatedRadius,
        color: _parseColor(cluster.zoneColor).withValues(alpha: cluster.zoneOpacity),
        borderColor: _parseColor(cluster.zoneColor),
        borderStrokeWidth: cluster.borderWidth,
        useRadiusInMeter: true, // Importante: usar radio en metros
      );
    }).toList();
  }

  /// Construye los marcadores de los clusters
  List<Marker> _buildClusterMarkers() {
    return clusters.map((cluster) {
      return Marker(
        point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onZoneTap?.call(cluster),
          child: Container(
            decoration: BoxDecoration(
              color: _parseColor(cluster.zoneColor),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                cluster.reportCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Parsea un color hexadecimal a Color
  Color _parseColor(String hexColor) {
    try {
      // Remover el # si existe
      String hex = hexColor.replaceAll('#', '');
      
      // Si es de 3 caracteres, expandir a 6
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }
      
      // Agregar alpha si no existe
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      // Color por defecto si hay error
      return Colors.red;
    }
  }
}

/// Widget para mostrar información de una zona de peligro
class DangerZoneInfoCard extends StatelessWidget {
  final ClusterEntity cluster;
  final VoidCallback? onClose;

  const DangerZoneInfoCard({
    super.key,
    required this.cluster,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _parseColor(cluster.zoneColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cluster.dominantIncidentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información de la zona
            _buildInfoRow('Radio de zona', '${cluster.calculatedRadius.toStringAsFixed(0)} metros'),
            _buildInfoRow('Reportes', '${cluster.reportCount} incidentes'),
            _buildInfoRow('Severidad promedio', '${cluster.averageSeverity.toStringAsFixed(1)}/5'),
            _buildInfoRow('Severidad máxima', '${cluster.maxSeverity}/5'),
            _buildInfoRow('Nivel de riesgo', cluster.riskLevel),
            
            const SizedBox(height: 12),
            
            // Tags
            if (cluster.tags.isNotEmpty) ...[
              Text(
                'Características:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: cluster.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey[100],
                  labelStyle: const TextStyle(fontSize: 12),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Parsea un color hexadecimal a Color
  Color _parseColor(String hexColor) {
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.red;
    }
  }
} 