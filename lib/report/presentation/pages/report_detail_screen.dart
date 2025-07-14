import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/report/presentation/viewmodels/get_report_viewmodel.dart';
import 'package:safy/report/presentation/widgets/my_reports/details_report_widget.dart';
import 'package:safy/report/presentation/widgets/my_reports/list_report_widget.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late final GetReportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.instance<GetReportViewModel>();

    _loadReport();
  }

  void _loadReport() {
    _viewModel.loadReport(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<GetReportViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const LoadingWidget();
            }

            if (viewModel.errorMessage != null) {
              return ErrorStateWidget(
                errorMessage: viewModel.errorMessage,
                onRetry: _loadReport,
              );
            }

            if (viewModel.report == null) {
              return const Center(
                child: Text(
                  'Reporte no encontrado',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return _buildReportDetail(viewModel.report!);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detalle del Reporte',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go(AppRoutesConstant.myReports); // o a donde quieras redirigir en fallback
          }
        },

        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
      ),
    );
  }

  Widget _buildReportDetail(report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportDetailHeaderCard(report: report),
          const SizedBox(height: 16),
          ReportDetailStatusCard(report: report),
          const SizedBox(height: 16),
          ReportDetailLocationCard(report: report),
          const SizedBox(height: 16),
          ReportDetailDescriptionCard(report: report),
          const SizedBox(height: 16),
          ReportDetailReporterCard(report: report),
        ],
      ),
    );
  }
}
