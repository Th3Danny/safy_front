import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioConfig {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor de logging (solo en debug)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }

    // Interceptor de autenticación
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Agregar token de autenticación si existe
        // final token = await TokenStorage.getToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Manejar errores globales (ej. 401 - token expirado)
        if (error.response?.statusCode == 401) {
          // Lógica para refrescar token o redirigir al login
          debugPrint('Token expirado - redirigiendo al login');
        }
        return handler.next(error);
      },
    ));

    return dio;
  }

  static String _getBaseUrl() {
    if (kDebugMode) {
      // URL para desarrollo local
      return 'http://192.168.100.9:8085';
    } else {
      // URL para producción
      return 'https://api.safy.app';
    }
  }
}
