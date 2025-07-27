import 'package:flutter/material.dart';
import 'package:safy/core/services/security/gps_spoofing_detector.dart';

/// Widget para mostrar el estado de seguridad del GPS
class GpsSecurityWidget extends StatelessWidget {
  final SpoofingDetectionResult? spoofingResult;
  final VoidCallback? onTap;

  const GpsSecurityWidget({super.key, this.spoofingResult, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (spoofingResult == null) {
      return const SizedBox.shrink(); // No mostrar nada si no hay resultado
    }

    // Solo mostrar si hay GPS falso
    if (!spoofingResult!.isSpoofed) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _getBorderColor().withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSecurityIcon(),
            const SizedBox(width: 8),
            _buildSecurityText(),
            const SizedBox(width: 8),
            _buildWarningIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Verificando GPS...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityIcon() {
    final isSpoofed = spoofingResult?.isSpoofed ?? false;
    final riskLevel = spoofingResult?.riskLevel ?? 'DESCONOCIDO';

    // Solo mostrar icono para GPS falso
    if (!isSpoofed) {
      return const SizedBox.shrink();
    }

    IconData iconData;
    Color iconColor;

    switch (riskLevel) {
      case 'CRÍTICO':
        iconData = Icons.security;
        iconColor = Colors.red;
        break;
      case 'ALTO':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor = Colors.yellow.shade700;
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  Widget _buildSecurityText() {
    final isSpoofed = spoofingResult?.isSpoofed ?? false;
    final riskLevel = spoofingResult?.riskLevel ?? 'DESCONOCIDO';
    final riskScore = spoofingResult?.riskScore ?? 0.0;

    // Solo mostrar texto para GPS falso
    if (!isSpoofed) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ubicación Falsa',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        Text(
          '${(riskScore * 100).toStringAsFixed(0)}% riesgo',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildWarningIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.warning, size: 12, color: Colors.red.shade700),
    );
  }

  Color _getBackgroundColor() {
    final isSpoofed = spoofingResult?.isSpoofed ?? false;
    final riskLevel = spoofingResult?.riskLevel ?? 'DESCONOCIDO';

    if (isSpoofed) {
      switch (riskLevel) {
        case 'CRÍTICO':
          return Colors.red.shade50;
        case 'ALTO':
          return Colors.orange.shade50;
        default:
          return Colors.yellow.shade50;
      }
    } else {
      return Colors.green.shade50;
    }
  }

  Color _getBorderColor() {
    final isSpoofed = spoofingResult?.isSpoofed ?? false;
    final riskLevel = spoofingResult?.riskLevel ?? 'DESCONOCIDO';

    if (isSpoofed) {
      switch (riskLevel) {
        case 'CRÍTICO':
          return Colors.red.shade300;
        case 'ALTO':
          return Colors.orange.shade300;
        default:
          return Colors.yellow.shade300;
      }
    } else {
      return Colors.green.shade300;
    }
  }
}

/// Widget expandido para mostrar detalles de seguridad del GPS
class GpsSecurityDetailsWidget extends StatelessWidget {
  final SpoofingDetectionResult spoofingResult;
  final VoidCallback? onClose;

  const GpsSecurityDetailsWidget({
    super.key,
    required this.spoofingResult,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRiskIndicator(),
          const SizedBox(height: 16),
          _buildIssuesList(),
          const SizedBox(height: 16),
          _buildRecommendations(),
          if (onClose != null) ...[
            const SizedBox(height: 16),
            _buildCloseButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          spoofingResult.isSpoofed ? Icons.security : Icons.verified,
          color: spoofingResult.riskColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spoofingResult.isSpoofed
                    ? 'GPS Falso Detectado'
                    : 'GPS Verificado',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nivel de riesgo: ${spoofingResult.riskLevel}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puntuación de Riesgo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: spoofingResult.riskScore,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(spoofingResult.riskColor),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(spoofingResult.riskScore * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildIssuesList() {
    if (spoofingResult.detectedIssues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'No se detectaron anomalías',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Problemas Detectados',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...spoofingResult.detectedIssues.map((issue) => _buildIssueItem(issue)),
      ],
    );
  }

  Widget _buildIssueItem(SpoofingCheck issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.description,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendaciones',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...spoofingResult.recommendations.map(
          (rec) => _buildRecommendationItem(rec),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onClose,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.grey.shade700,
          elevation: 0,
        ),
        child: const Text('Cerrar'),
      ),
    );
  }
}
