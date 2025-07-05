import 'package:geolocator/geolocator.dart';
import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/domain/entities/location.dart';


class GetCurrentLocationUseCase {
  Future<Location> execute() async {
    try {
      // Verificar permisos
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          throw LocationFailure('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationFailure('Permisos de ubicación permanentemente denegados');
      }

      // Verificar servicios de ubicación
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationFailure('Servicios de ubicación desactivados');
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (e is LocationFailure) rethrow;
      throw LocationFailure('Error obteniendo ubicación: $e');
    }
  }
}