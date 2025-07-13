import 'package:safy/report/data/dtos/report_response_dto.dart';

class ReportsPageResponseDto {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final List<ReportResponseDto> reports;

  const ReportsPageResponseDto({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.reports,
  });

  factory ReportsPageResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final reportsJson = data['reports'] as List;
    
    return ReportsPageResponseDto(
      currentPage: data['currentPage'],
      totalPages: data['totalPages'],
      totalElements: data['totalElements'],
      reports: reportsJson
          .map((item) => ReportResponseDto.fromJson({'data': item}))
          .toList(),
    );
  }
}