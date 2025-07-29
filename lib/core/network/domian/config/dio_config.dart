import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';

class DioConfig {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
        headers: ApiConstants.headers,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final sessionManager = SessionManager.instance;
            final token = sessionManager.accessToken;

            if (token != null && sessionManager.isLoggedIn) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Silent error handling for production
          }

          return handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final sessionManager = SessionManager.instance;
              await sessionManager.clearSession();
            } catch (e) {
              // Silent error handling for production
            }
          }

          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
