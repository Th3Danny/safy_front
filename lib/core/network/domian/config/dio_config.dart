import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart'; // 👈 Importar

class DioConfig {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl, // 👈 Usar constante en lugar de hardcode
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      headers: ApiConstants.headers, // 👈 Usar headers de constantes
    ));

    // Resto del código igual...
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

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final sessionManager = SessionManager.instance;
          final token = sessionManager.accessToken;
          
          if (token != null && sessionManager.isLoggedIn) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('[DioConfig] 🔑 Token agregado para: ${options.path}');
          } else {
            debugPrint('[DioConfig] ⚠️ No hay token disponible para: ${options.path}');
          }
        } catch (e) {
          debugPrint('[DioConfig] ❌ Error agregando token: $e');
        }
        
        return handler.next(options);
      },
      
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          debugPrint('[DioConfig] 🚨 Token expirado o inválido (401)');
          
          try {
            final sessionManager = SessionManager.instance;
            await sessionManager.clearSession();
            debugPrint('[DioConfig] 🧹 Sesión limpiada');
          } catch (e) {
            debugPrint('[DioConfig] ❌ Error manejando 401: $e');
          }
        }
        
        return handler.next(error);
      },
    ));

    return dio;
  }
}