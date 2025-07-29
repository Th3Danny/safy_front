import 'package:flutter/material.dart';
import 'package:safy/report/presentation/widgets/report_form.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';


class CreateReportScreen extends StatelessWidget {
  final Map<String, dynamic>? extraData;
  
  const CreateReportScreen({super.key, this.extraData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Reporte',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ReportForm(extraData: extraData),
        ),
      ),
    );
  }
}
