import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class GetReportsForMapUseCase {
  final ReportRepository _repository;

  GetReportsForMapUseCase(this._repository);

  Future<List<ReportInfoEntity>> execute({
    required String userId,
    int? page,
    int? pageSize,
    required double latitude,
    required double longitude,
    
  }) async {
    return await _repository.getReports(
      userId: userId,
      page: page,
      pageSize: pageSize,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
