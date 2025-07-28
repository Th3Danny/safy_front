import 'package:flutter/material.dart';
import 'package:safy/core/services/security/gps_spoofing_detector.dart';

/// Widget simple para mostrar el estado de seguridad del GPS
class GpsSecurityWidget extends StatelessWidget {
  final SpoofingDetectionResult? spoofingResult;
  final VoidCallback? onTap;
  final VoidCallback? onReset;

  const GpsSecurityWidget({
    super.key,
    this.spoofingResult,
    this.onTap,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (spoofingResult == null) {
      return const SizedBox.shrink();
    }

    // Solo mostrar si hay GPS falso
    if (!spoofingResult!.isSpoofed) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap ?? () => _showDetailsDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'GPS Falso (${(spoofingResult!.riskScore * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.security, color: Colors.red),
                const SizedBox(width: 8),
                const Text('GPS Falso Detectado'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se detectó posible GPS falso con ${(spoofingResult!.riskScore * 100).toStringAsFixed(1)}% de riesgo.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Problemas detectados:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...spoofingResult!.detectedIssues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recomendaciones:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...spoofingResult!.recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (onReset != null)
                TextButton(
                  onPressed: () {
                    onReset!();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Resetear Detector'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }
}

/// Widget banner para mostrar advertencia de GPS falso
class GpsSpoofingBanner extends StatelessWidget {
  final SpoofingDetectionResult? spoofingResult;
  final VoidCallback? onDismiss;
  final VoidCallback? onReset;

  const GpsSpoofingBanner({
    super.key,
    this.spoofingResult,
    this.onDismiss,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (spoofingResult == null || !spoofingResult!.isSpoofed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS Falso Detectado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: Colors.red.shade700),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se detectó posible GPS falso (${(spoofingResult!.riskScore * 100).toStringAsFixed(1)}% de riesgo). '
            'Esto puede afectar la precisión de la información de seguridad.',
            style: TextStyle(fontSize: 14, color: Colors.red.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onReset != null)
                ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Resetear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showDetailsDialog(context),
                child: const Text('Ver Detalles'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del GPS'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problemas detectados:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...spoofingResult!.detectedIssues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (onReset != null)
                TextButton(
                  onPressed: () {
                    onReset!();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Resetear Detector'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }
}
