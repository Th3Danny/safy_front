import 'package:flutter/material.dart';
import 'package:safy/report/domain/entities/cluster_entity.dart';

/// Widget de alerta que se muestra cuando el usuario entra en una zona peligrosa
class DangerZoneAlertWidget extends StatelessWidget {
  final ClusterEntity cluster;
  final double distance;
  final VoidCallback? onSafeRoute;
  final VoidCallback? onReport;
  final VoidCallback? onDismiss;


  const DangerZoneAlertWidget({
    super.key,
    required this.cluster,
    required this.distance,
    this.onSafeRoute,
    this.onReport,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de advertencia
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '▲ ZONA PELIGROSA DETECTADA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Mensaje
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Estás cerca de una zona con reportes recientes de incidentes. Mantente alerta y considera usar una ruta alternativa.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Información adicional
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Distancia', '${distance.toStringAsFixed(0)}m'),
                _buildInfoItem(
                  'Severidad',
                  _getSeverityText(cluster.severityNumber ?? 1),
                ),
                _buildInfoItem('Reportes', '${cluster.reportCount}'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Botón de ruta segura
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSafeRoute,
                    icon: const Icon(Icons.route, color: Colors.white),
                    label: const Text(
                      'Ruta Segura',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de reportar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.report_problem, color: Colors.white),
                    label: const Text(
                      'Reportar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón de continuar
          TextButton.icon(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            label: const Text(
              'Entendido, continuar',
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 5:
        return 'CRÍTICA';
      case 4:
        return 'ALTA';
      case 3:
        return 'MEDIA';
      case 2:
        return 'BAJA';
      default:
        return 'BAJA';
    }
  }
}
