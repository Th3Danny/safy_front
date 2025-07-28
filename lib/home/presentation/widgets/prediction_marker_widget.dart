import 'package:flutter/material.dart';
import 'package:safy/home/domain/entities/prediction.dart';

class PredictionMarkerWidget extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback? onTap;

  const PredictionMarkerWidget({
    super.key,
    required this.prediction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRiskColor(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(_getRiskIcon(), color: Colors.white, size: 20),
      ),
    );
  }

  Color _getRiskColor() {
    switch (prediction.riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      case 'CRITICAL':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon() {
    switch (prediction.riskLevel.toUpperCase()) {
      case 'LOW':
        return Icons.info_outline;
      case 'MEDIUM':
        return Icons.warning_amber_outlined;
      case 'HIGH':
        return Icons.warning_rounded;
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline;
    }
  }
}

class PredictionInfoCard extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback? onClose;

  const PredictionInfoCard({super.key, required this.prediction, this.onClose});

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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getRiskColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getRiskIcon(), color: _getRiskColor(), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicción de Riesgo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      prediction.riskDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getRiskColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Información detallada
          _buildInfoRow(
            'Confianza',
            '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
          ),
          _buildInfoRow(
            'Riesgo de actividad',
            '${(prediction.highActivityRisk * 100).toStringAsFixed(1)}%',
          ),
          _buildInfoRow(
            'Crímenes predichos',
            prediction.predictedCrimeCount.toStringAsFixed(0),
          ),
          _buildInfoRow('Modelo', prediction.modelVersion),
          _buildInfoRow('Zona ID', prediction.zoneId.toString()),

          const SizedBox(height: 12),

          // Timestamp
          Text(
            'Predicción para: ${_formatDateTime(prediction.timestamp)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor() {
    switch (prediction.riskLevel.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      case 'CRITICAL':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon() {
    switch (prediction.riskLevel.toUpperCase()) {
      case 'LOW':
        return Icons.info_outline;
      case 'MEDIUM':
        return Icons.warning_amber_outlined;
      case 'HIGH':
        return Icons.warning_rounded;
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
