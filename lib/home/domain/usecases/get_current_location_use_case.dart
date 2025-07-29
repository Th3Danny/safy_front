
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/core/errors/failures.dart';

class LocationConfig {
  final LocationAccuracy accuracy;
  final Duration timeout;

  const LocationConfig({
    this.accuracy = LocationAccuracy.high,
    this.timeout = const Duration(seconds: 15),
  });
}

class GetCurrentLocationUseCase {
  // ⚠️ FUNCIÓN ESTÁTICA para compute (CRÍTICO)
  static Future<Location> _getLocationInIsolate(LocationConfig config) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos denegados permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: config.accuracy,
        timeLimit: config.timeout,
      );

      // ✅ Usar tu entidad Location existente
      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error obteniendo ubicación: $e');
    }
  }

  // 🚀 MÉTODO QUE USA COMPUTE (no bloquea UI)
  Future<Location> execute({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final config = LocationConfig(
        accuracy: accuracy,
        timeout: timeout,
      );

      // ⚠️ ESTO ES LO QUE EVITA EL CRASH
      return await compute(_getLocationInIsolate, config);
    } catch (e) {
      throw ServerFailure('Error obteniendo ubicación: $e');
    }
  }

  // Método stream (opcional, mantener si lo usas)
  Stream<Location> getLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    double distanceFilter = 10.0,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter.toInt(),
      ),
    ).map((position) => Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    ));
  }
}
