import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/presentation/widgets/report_utils.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.blue),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Error al cargar reportes',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.description,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes reportes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primer reporte para ayudar\na mantener segura tu comunidad',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutesConstant.createReport),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Crear Reporte'),
          ),
        ],
      ),
    );
  }
}

class ReportsListWidget extends StatelessWidget {
  final List<ReportInfoEntity> reports;
  final VoidCallback onRefresh;
  final Function(String) onReportTap;

  const ReportsListWidget({
    super.key,
    required this.reports,
    required this.onRefresh,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ReportCardWidget(
            report: report,
            onTap: () => onReportTap(report.id),
          );
        },
      ),
    );
  }
}

class ReportCardWidget extends StatelessWidget {
  final ReportInfoEntity report;
  final VoidCallback onTap;

  const ReportCardWidget({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportHeaderWidget(report: report),
              const SizedBox(height: 12),
              ReportDescriptionWidget(description: report.description),
              const SizedBox(height: 12),
              ReportLocationWidget(address: report.address),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportHeaderWidget extends StatelessWidget {
  final ReportInfoEntity report;

  const ReportHeaderWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IncidentIconWidget(incidentType: report.incident_type),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                ReportUtils.formatIncidentType(report.incident_type),
                style: TextStyle(
                  fontSize: 14,
                  color: ReportUtils.getIncidentColor(report.incident_type),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class IncidentIconWidget extends StatelessWidget {
  final String incidentType;

  const IncidentIconWidget({super.key, required this.incidentType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ReportUtils.getIncidentColor(incidentType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        ReportUtils.getIncidentIcon(incidentType),
        color: ReportUtils.getIncidentColor(incidentType),
        size: 20,
      ),
    );
  }
}

class ReportDescriptionWidget extends StatelessWidget {
  final String description;

  const ReportDescriptionWidget({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class ReportLocationWidget extends StatelessWidget {
  final String? address;

  const ReportLocationWidget({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            address ?? 'Dirección no disponible',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}