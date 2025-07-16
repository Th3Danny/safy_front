import 'package:dio/dio.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';
import 'package:safy/core/network/error_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
        headers: ApiConstants.headers,
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    _dio.interceptors.add(ErrorInterceptor());
  }

  Dio get dio => _dio;
}
