import 'package:flutter/material.dart';

class ReportUtils {
  static IconData getIncidentIcon(String incidentType) {
    switch (incidentType.toUpperCase()) {
      case 'HARASSMENT':
        return Icons.report_problem;
      case 'ROBBERY_ASSAULT':
        return Icons.security;
      case 'KIDNAPPING':
        return Icons.warning_amber;
      case 'GANG_VIOLENCE':
        return Icons.groups;
      case 'EMERGENCY':
        return Icons.emergency;
      case 'SEXUAL_VIOLENCE':
        return Icons.block;
      default:
        return Icons.description;
    }
  }

  static Color getIncidentColor(String incidentType) {
    switch (incidentType.toUpperCase()) {
      case 'HARASSMENT':
        return Colors.orange;
      case 'ROBBERY_ASSAULT':
        return Colors.red;
      case 'KIDNAPPING':
        return Colors.purple;
      case 'GANG_VIOLENCE':
        return Colors.indigo;
      case 'EMERGENCY':
        return Colors.red;
      case 'SEXUAL_VIOLENCE':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  static String formatIncidentType(String incidentType) {
    switch (incidentType.toUpperCase()) {
      case 'HARASSMENT':
        return 'Acoso callejero';
      case 'ROBBERY_ASSAULT':
        return 'Asalto/Robo';
      case 'KIDNAPPING':
        return 'Secuestro';
      case 'GANG_VIOLENCE':
        return 'Violencia de pandillas';
      case 'EMERGENCY':
        return 'Emergencia';
      case 'SEXUAL_VIOLENCE':
        return 'Violencia sexual';
      default:
        return incidentType;
    }
  }

  static String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  static String formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Widget buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case 'VERIFIED':
        color = Colors.green;
        text = 'Verificado';
        break;
      case 'RESOLVED':
        color = Colors.blue;
        text = 'Resuelto';
        break;
      case 'REJECTED':
        color = Colors.red;
        text = 'Rechazado';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget buildSeverityIndicator(int severity) {
    String severityText;
    Color severityColor;

    switch (severity) {
      case 1:
        severityText = 'Bajo';
        severityColor = Colors.green;
        break;
      case 2:
        severityText = 'Medio';
        severityColor = Colors.orange;
        break;
      case 3:
        severityText = 'Alto';
        severityColor = Colors.red;
        break;
      default:
        severityText = 'Desconocido';
        severityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.priority_high,
            size: 16,
            color: severityColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Severidad: $severityText',
            style: TextStyle(
              fontSize: 14,
              color: severityColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
