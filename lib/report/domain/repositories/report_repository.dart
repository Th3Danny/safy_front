import '../entities/report.dart';

abstract class ReportRepository {
  // Future<List<ReportInfoEntity>> getReports({
  //   required String userId,
  //   int? page,
  //   int? pageSize,
  // });

 Future<ReportInfoEntity> getReportById({required String id});

  Future<ReportInfoEntity> createReport({
    required String title,
    required String userName,
    required String incidentType,
    required String location,
    required DateTime dateTime,
    required String description,
  });


 // Future<ReportInfoEntity> updateReport(ReportInfoEntity report);

 // Future<void> deleteReport(String reportId);
}