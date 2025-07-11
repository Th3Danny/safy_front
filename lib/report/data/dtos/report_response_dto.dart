import 'package:safy/report/data/dtos/report_request_dto.dart';
import 'package:safy/report/domain/entities/report.dart';

class ReportResponseDto {
  final ReportRequestDto report;

  const ReportResponseDto({required this.report});

  factory ReportResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return ReportResponseDto(
      report: ReportRequestDto.fromJson(data['report'] ?? {})
        
    );
  }

  ReportInfoEntity toDomainEntity() {
    return report.toDomainEntity();
  }
}
