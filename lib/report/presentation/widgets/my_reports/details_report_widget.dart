import 'package:flutter/material.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/presentation/widgets/report_utils.dart';

class ReportDetailHeaderCard extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportDetailHeaderCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ReportUtils.getIncidentColor(report.incident_type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ReportUtils.getIncidentIcon(report.incident_type),
                  color: ReportUtils.getIncidentColor(report.incident_type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReportUtils.formatIncidentType(report.incident_type),
                      style: TextStyle(
                        fontSize: 16,
                        color: ReportUtils.getIncidentColor(report.incident_type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ReportUtils.buildSeverityIndicator(report.severity),
              const Spacer(),
              Text(
                'ID: #${report.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportDetailStatusCard extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportDetailStatusCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado del Reporte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ReportTimelineWidget(report: report),
        ],
      ),
    );
  }
}

class ReportDetailLocationCard extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportDetailLocationCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.address ?? 'Dirección no disponible',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Lat: ${report.latitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Lng: ${report.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportDetailDescriptionCard extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportDetailDescriptionCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportDetailReporterCard extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportDetailReporterCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Reportero',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                report.isAnonymous ? Icons.person_off : Icons.person,
                color: report.isAnonymous ? Colors.grey[600] : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                report.isAnonymous ? 'Reporte anónimo' : report.reporterName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportTimelineWidget extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportTimelineWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimelineItemWidget(
          icon: Icons.add_circle,
          title: 'Reporte creado',
          date: 'Fecha no disponible', // Cambiar cuando tengas createdAt
          color: Colors.blue,
          completed: true,
        ),
        // Agregar más items del timeline cuando estén disponibles en tu entidad
        // if (report.verifiedAt != null)
        //   TimelineItemWidget(
        //     icon: Icons.verified,
        //     title: 'Reporte verificado',
        //     date: ReportUtils.formatFullDate(report.verifiedAt!),
        //     color: Colors.green,
        //     completed: true,
        //   ),
      ],
    );
  }
}

class TimelineItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final Color color;
  final bool completed;

  const TimelineItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.date,
    required this.color,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: completed ? color : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: completed ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}