import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

class GetReportUseCase {
  final ReportRepository _repository;

  GetReportUseCase(this._repository);
  
  Future<ReportInfoEntity> execute(String id) async {
    return await _repository.getReportById(id: id);
  }

}
