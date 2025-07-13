import '../entities/report.dart';

abstract class ReportRepository {
  Future<List<ReportInfoEntity>> getReports({
    required String userId,
    int? page,
    int? pageSize,
    double? latitude,
    double? longitude,

  });

 Future<ReportInfoEntity> getReportById({required String id});

   Future<ReportInfoEntity> createReport({
    required String title,
    required String description,
    required String incident_type,
    required double latitude,
    required double longitude,
    String? address,
    required String reporterName,
    String? reporterEmail,
    required int severity,
    required bool isAnonymous,
    //required DateTime dateTime,
  });


 // Future<ReportInfoEntity> updateReport(ReportInfoEntity report);

 // Future<void> deleteReport(String reportId);
}