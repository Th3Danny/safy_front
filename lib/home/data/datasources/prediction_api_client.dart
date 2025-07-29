import 'package:dio/dio.dart';
import 'package:safy/home/data/dtos/prediction_request_dto.dart';
import 'package:safy/home/data/dtos/prediction_response_dto.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';

class PredictionApiClient {
  final Dio _dio;

  PredictionApiClient(this._dio);

  // 🆕 NUEVO: Cliente Dio específico para predicciones
  late final Dio _predictionDio = Dio(
    BaseOptions(
      baseUrl: 'https://datamining.devquailityup.xyz',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Obtiene predicciones de zonas de peligro para una ubicación y tiempo específicos
  Future<List<PredictionResponseDto>> getPredictions({
    required PredictionRequestDto request,
  }) async {
    try {
      print(
        '[PredictionApiClient] 🔮 Obteniendo predicciones para: ${request.latitude}, ${request.longitude}',
      );
      print('[PredictionApiClient] 📅 Timestamp: ${request.timestamp}');

      final response = await _predictionDio.post(
        '/api/v1/predictions/predict',
        data: [request.toJson()], // Enviar como array según la especificación
      );

      print(
        '[PredictionApiClient] ✅ Respuesta recibida: ${response.statusCode}',
      );

      if (response.data is List) {
        final predictionsData = response.data as List;
        return predictionsData
            .map(
              (json) =>
                  PredictionResponseDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Respuesta inesperada del servidor: se esperaba una lista',
        );
      }
    } on DioException catch (e) {
      print('[PredictionApiClient] ❌ Error en la petición: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('[PredictionApiClient] ❌ Error inesperado: $e');
      throw Exception('Error obteniendo predicciones: $e');
    }
  }

  /// Obtiene predicciones para múltiples ubicaciones
  Future<List<PredictionResponseDto>> getPredictionsForMultipleLocations({
    required List<PredictionRequestDto> requests,
  }) async {
    try {
      print(
        '[PredictionApiClient] 🔮 Obteniendo predicciones para ${requests.length} ubicaciones',
      );

      final requestData = requests.map((req) => req.toJson()).toList();
      final response = await _predictionDio.post(
        '/api/v1/predictions/predict',
        data: requestData,
      );

      print(
        '[PredictionApiClient] ✅ Respuesta recibida: ${response.statusCode}',
      );

      if (response.data is List) {
        final predictionsData = response.data as List;
        return predictionsData
            .map(
              (json) =>
                  PredictionResponseDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Respuesta inesperada del servidor: se esperaba una lista',
        );
      }
    } on DioException catch (e) {
      print('[PredictionApiClient] ❌ Error en la petición: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('[PredictionApiClient] ❌ Error inesperado: $e');
      throw Exception('Error obteniendo predicciones: $e');
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Tiempo de conexión agotado');
      case DioExceptionType.connectionError:
        return Exception('Error de conexión');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return Exception('Error $statusCode: $message');
      default:
        return Exception('Error desconocido: ${e.message}');
    }
  }
}
