import 'package:flutter/material.dart';
import 'package:safy/report/presentation/widgets/report_form.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';


class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Reporte',
        showBackButton: true,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: ReportForm(),
          
        ),
      ),
    );
  }
}