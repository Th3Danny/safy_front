import 'package:dio/dio.dart';
import 'package:safy/auth/domain/exceptions/auth_exceptions.dart';
import 'package:safy/report/data/dtos/report_request_dto.dart';
import 'package:safy/report/data/dtos/report_response_dto.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';
class ReportApiClient {
  final Dio _dio;

  ReportApiClient(this._dio);

  Future<ReportResponseDto> getReportById(String id) async {
  try {
    final response = await _dio.get('${ApiConstants.reports}/$id');
    return ReportResponseDto.fromJson(response.data);
  } on DioException catch (e) {
    _handleDioError(e);
    rethrow;
  }
}


  Future<ReportResponseDto> createReport(ReportRequestDto requestDto) async {
    try {
      final response = await _dio.post(
        ApiConstants.createReport,
        data: requestDto.toJson(),
      );

      return ReportResponseDto.fromJson(response.data);

    }on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }



   // ===== Manejo de errores centralizado =====
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      throw const InvalidCredentialsException('Credenciales inválidas');
    } else if (e.response?.statusCode == 409) {
      throw const AuthException('Conflicto: posible duplicado');
    } else if (e.response?.statusCode == 422) {
      throw ReportValidationException('Datos inválidos', e.response?.data['errors'] ?? {});
    } else if (e.response?.statusCode == 500) {
      throw const AuthException('Error del servidor');
    } else {
      throw AuthException('Error inesperado: ${e.message}');
    }
  }
}
