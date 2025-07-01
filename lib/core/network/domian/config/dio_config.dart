import 'package:dio/dio.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';
import 'package:safy/core/session/session_manager.dart';

class DioConfig {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.fullUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: ApiConstants.headers,
    ));

    // Logging interceptor (solo en debug)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      request: true,
      logPrint: (object) {
        // Solo mostrar logs en debug
        assert(() {
          print('[DIO] $object');
          return true;
        }());
      },
    ));

    // Auth interceptor - agregar token automáticamente
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Obtener token del SessionManager
          final token = SessionManager.instance.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('[DIO] Token agregado a la request');
          }
        } catch (e) {
          print('[DIO] Error agregando token: $e');
        }
        return handler.next(options);
      },
      
      onResponse: (response, handler) async {
        print('[DIO] Response: ${response.statusCode} - ${response.requestOptions.path}');
        return handler.next(response);
      },
      
      onError: (error, handler) async {
        print('[DIO] Error: ${error.response?.statusCode} - ${error.requestOptions.path}');
        
        // Manejo automático de errores 401 (token expirado)
        if (error.response?.statusCode == 401) {
          print('[DIO] Token expirado (401), cerrando sesión...');
          
          try {
            // Limpiar sesión automáticamente
            await SessionManager.instance.clearSession();
            
            // Opcional: Navegar a login
            // NavigationService.navigateToLogin();
          } catch (e) {
            print('[DIO] Error limpiando sesión: $e');
          }
        }
        
        return handler.next(error);
      },
    ));

    return dio;
  }

  /// Crear una instancia de Dio sin interceptores (para requests públicos)
  static Dio createPublicDio() {
    return Dio(BaseOptions(
      baseUrl: ApiConstants.fullUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: ApiConstants.headers,
    ));
  }
}
