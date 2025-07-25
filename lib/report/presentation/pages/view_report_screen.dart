import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/report/presentation/viewmodels/my_get_reports_viewmodel.dart'; // 🔧 TU ARCHIVO
import 'package:safy/report/presentation/widgets/my_reports/list_report_widget.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final GetReportsViewModel _viewModel; // 🔧 TU CLASE

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.instance<GetReportsViewModel>(); // 🔧 TU CLASE
    _loadUserReports();
  }

  void _loadUserReports() {
    final userId = SessionManager.instance.currentUser?.id;
    if (userId != null) {
      // 🔧 SIN coordenadas para obtener MIS reportes
      _viewModel.loadReports(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: Consumer<GetReportsViewModel>( // 🔧 TU CLASE
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const LoadingWidget();
            }

            if (viewModel.hasError) {
              return ErrorStateWidget(
                errorMessage: viewModel.errorMessage,
                onRetry: _loadUserReports,
              );
            }

            if (viewModel.reports.isEmpty) {
              return const EmptyStateWidget();
            }

            return ReportsListWidget(
              reports: viewModel.reports,
              onRefresh: _loadUserReports,
              onReportTap: _navigateToReportDetail,
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Reportes',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
         onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go(AppRoutesConstant.home);
           }
        },
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
      ),
      actions: [
        IconButton(
          onPressed: () => context.go(AppRoutesConstant.createReport),
          icon: const Icon(Icons.add, color: Colors.blue),
        ),
      ],
    );
  }

  void _navigateToReportDetail(String reportId) {
    context.go(AppRoutesConstant.reportDetail, extra: {'reportId': reportId});
  }
}