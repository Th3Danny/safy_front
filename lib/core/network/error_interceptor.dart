import 'package:dio/dio.dart';
import 'package:safy/core/errors/api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null && err.response!.data != null) {
      try {
        final data = err.response!.data as Map<String, dynamic>;
        final message = data['message'] as String;
        final code = data['code'] as String?;
        final statusCode = data['statusCode'] as int?;

        final apiException = ApiException(
          message: message,
          code: code,
          statusCode: statusCode,
        );

        return handler.reject(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: apiException,
          type: err.type,
        ));
      } catch (e) {
        // Fallback for parsing errors or unexpected response structures
      }
    }

    // Fallback for other types of errors
    final apiException =
        ApiException(message: err.message ?? 'Ocurrió un error inesperado');
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      error: apiException,
      type: err.type,
    ));
  }
}
