import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class NotificationService {
  static const double _notificationDistance = 500.0; // metros
  static final Set<String> _shownNotifications = <String>{};
  static LatLng? _lastKnownLocation;

  /// Maneja notificaciones dinámicas basadas en la ubicación
  static void handleDynamicNotifications(MapViewModel mapViewModel) {
    final currentLocation = mapViewModel.currentLocation;

    // Si es la primera vez, solo guardar la ubicación
    if (_lastKnownLocation == null) {
      _lastKnownLocation = currentLocation;
      return;
    }

    // Calcular distancia movida
    final distance = _calculateDistance(_lastKnownLocation!, currentLocation);

    // Si se movió más de la distancia de notificación
    if (distance > _notificationDistance) {
      _checkNearbyDangerZones(mapViewModel);
      _lastKnownLocation = currentLocation;
    }
  }

  /// Verifica zonas de peligro cercanas
  static void _checkNearbyDangerZones(MapViewModel mapViewModel) {
    if (!mapViewModel.showClusters || mapViewModel.clusters.isEmpty) return;

    final currentLocation = mapViewModel.currentLocation;
    final nearbyZones = <String>[];

    for (final cluster in mapViewModel.clusters) {
      final distance = _calculateDistance(
        currentLocation,
        LatLng(cluster.centerLatitude, cluster.centerLongitude),
      );

      // Si está a menos de 1km y es de alta severidad
      if (distance < 1000 && cluster.severityNumber >= 3) {
        final zoneId = '${cluster.centerLatitude}_${cluster.centerLongitude}';
        if (!_shownNotifications.contains(zoneId)) {
          nearbyZones.add(zoneId);
          _showDangerZoneNotification(cluster, distance);
        }
      }
    }

    // Limpiar notificaciones antiguas
    _shownNotifications.clear();
    _shownNotifications.addAll(nearbyZones);
  }

  /// Muestra notificación de zona de peligro
  static void _showDangerZoneNotification(dynamic cluster, double distance) {
    final severity = cluster.severityNumber ?? 1;
    final reportCount = cluster.reportCount ?? 0;

    Color notificationColor;
    String severityText;

    if (severity >= 4) {
      notificationColor = Colors.red;
      severityText = 'ALTA';
    } else if (severity >= 3) {
      notificationColor = Colors.orange;
      severityText = 'MEDIA';
    } else {
      notificationColor = Colors.yellow;
      severityText = 'BAJA';
    }

    // Aquí podrías usar un sistema de notificaciones real
    // Removed debug print
    print(
      '🚨 [NotificationService] Distancia: ${distance.toStringAsFixed(0)}m',
    );
    // Removed debug print
    // Removed debug print
    // Removed debug print
  }

  /// Calcula distancia entre dos puntos
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros

    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Limpia notificaciones mostradas
  static void clearNotifications() {
    _shownNotifications.clear();
    _lastKnownLocation = null;
  }
}
