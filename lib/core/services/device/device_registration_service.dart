import 'package:dio/dio.dart';
import 'package:safy/auth/data/dtos/device_register_dto.dart';
import 'package:safy/core/network/domian/constants/api_client_constants.dart';
import 'package:safy/core/services/device/device_info_service.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/core/session/session_manager.dart';

class DeviceRegistrationService {
  static final DeviceRegistrationService _instance =
      DeviceRegistrationService._internal();
  factory DeviceRegistrationService() => _instance;
  DeviceRegistrationService._internal();

  final Dio _dio = Dio();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final SessionManager _sessionManager = SessionManager.instance;

  /// Registra el dispositivo en el backend
  Future<void> registerDevice({
    required String fcmToken,
    required Location location,
  }) async {
    try {
      // Removed debug print
      // Removed debug print
      print(
        '[DeviceRegistrationService] 🔧 Tipo de dispositivo: ${_deviceInfoService.getDeviceType()}',
      );

      // Obtener el token de acceso
      final accessToken = _sessionManager.accessToken;
      if (accessToken == null) {
        // Removed debug print
        return;
      }

      // Removed debug print

      final deviceDto = DeviceRegisterDto(
        fcmToken: fcmToken,
        deviceType: _deviceInfoService.getDeviceType(),
        latitude: location.latitude,
        longitude: location.longitude,
      );

      // Crear headers con autorización
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['Authorization'] = 'Bearer $accessToken';

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.registerDevice}',
        data: deviceDto.toJson(),
        options: Options(headers: headers),
      );

      // Removed debug print
      // Removed debug print
    } on DioException catch (e) {
      // Removed debug print
      // Removed debug print
      // Removed debug print
      // No lanzar excepción para no interrumpir el flujo de registro
    } catch (e) {
      // Removed debug print
      // No lanzar excepción para no interrumpir el flujo de registro
    }
  }

  /// Registra el dispositivo con ubicación por defecto (para casos donde no se puede obtener ubicación)
  Future<void> registerDeviceWithDefaultLocation({
    required String fcmToken,
  }) async {
    // Ubicación por defecto (Tuxtla Gutiérrez, Centro)
    final defaultLocation = Location(
      latitude: 16.7569,
      longitude: -93.1292,
      timestamp: DateTime.now(),
    );

    await registerDevice(fcmToken: fcmToken, location: defaultLocation);
  }
}
