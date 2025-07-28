import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundDangerDetectionService {
  static const String _notificationChannelId = 'danger_detection_channel';
  static const String _notificationChannelName = 'Detección de Peligro';
  static const String _notificationChannelDescription = 'Notificaciones de zonas de peligro';

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static Timer? _locationTimer;
  static List<Map<String, dynamic>> _cachedClusters = [];
  static DateTime _lastClusterUpdate = DateTime.now().subtract(const Duration(minutes: 5));
  static bool _isServiceRunning = false;

  /// Inicializa el servicio
  static Future<void> initialize() async {
    await _initializeNotifications();
    print('✅ [BackgroundService] Servicio inicializado');
  }

  /// Inicializa las notificaciones locales
  static Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Crear canal de notificación para Android
    const androidChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Inicia el monitoreo en segundo plano
  static Future<void> startMonitoring() async {
    if (_isServiceRunning) {
      print('⚠️ [BackgroundService] El servicio ya está ejecutándose');
      return;
    }

    // Verificar permisos de ubicación
    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ [BackgroundService] Permisos de ubicación denegados');
        return;
      }
    }

    _isServiceRunning = true;
    await _startLocationMonitoring();
    print('✅ [BackgroundService] Monitoreo iniciado');
  }

  /// Detiene el monitoreo
  static Future<void> stopMonitoring() async {
    _locationTimer?.cancel();
    _isServiceRunning = false;
    print('🛑 [BackgroundService] Monitoreo detenido');
  }

  /// Inicia el monitoreo de ubicación
  static Future<void> _startLocationMonitoring() async {
    print('📍 [BackgroundService] Iniciando monitoreo de ubicación');

    _locationTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!_isServiceRunning) {
        timer.cancel();
        return;
      }

      try {
        await _checkCurrentLocation();
      } catch (e) {
        print('❌ [BackgroundService] Error en monitoreo: $e');
      }
    });

    // Verificación inicial
    await _checkCurrentLocation();
  }

  /// Verifica la ubicación actual y detecta zonas de peligro
  static Future<void> _checkCurrentLocation() async {
    try {
      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('📍 [BackgroundService] Ubicación actual: ${position.latitude}, ${position.longitude}');

      // Actualizar clusters si es necesario
      await _updateClustersIfNeeded();

      // Verificar si está cerca de algún cluster
      await _checkNearbyClusters(position);

    } catch (e) {
      print('❌ [BackgroundService] Error obteniendo ubicación: $e');
    }
  }

  /// Actualiza los clusters si han pasado más de 5 minutos
  static Future<void> _updateClustersIfNeeded() async {
    final now = DateTime.now();
    if (now.difference(_lastClusterUpdate).inMinutes >= 5) {
      await _fetchClusters();
      _lastClusterUpdate = now;
    }
  }

  /// Obtiene los clusters del servidor
  static Future<void> _fetchClusters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url') ?? 'https://api.safy.com';
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [BackgroundService] No hay token de autenticación');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/clusters'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _cachedClusters = List<Map<String, dynamic>>.from(data['data']['clusters'] ?? []);
          print('✅ [BackgroundService] Clusters actualizados: ${_cachedClusters.length}');
        }
      }
    } catch (e) {
      print('❌ [BackgroundService] Error obteniendo clusters: $e');
    }
  }

  /// Verifica si está cerca de algún cluster
  static Future<void> _checkNearbyClusters(Position position) async {
    final shownNotifications = await _getShownNotifications();

    for (final cluster in _cachedClusters) {
      final clusterLat = cluster['centerLatitude']?.toDouble() ?? 0.0;
      final clusterLng = cluster['centerLongitude']?.toDouble() ?? 0.0;

      // Calcular distancia
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        clusterLat,
        clusterLng,
      );

      final severity = cluster['severityNumber']?.toInt() ?? 1;
      final reportCount = cluster['reportCount']?.toInt() ?? 0;
      final clusterId = cluster['id']?.toString() ?? '';

      // Radio de peligro basado en severidad y reportes
      double dangerRadius = 100.0; // Radio base
      if (severity >= 4) dangerRadius += 50;
      if (severity >= 3) dangerRadius += 30;
      if (severity >= 2) dangerRadius += 20;
      if (reportCount >= 10) dangerRadius += 40;
      if (reportCount >= 5) dangerRadius += 20;

      // Verificar si está dentro del radio de peligro
      if (distance <= dangerRadius) {
        // Verificar si ya se mostró esta notificación
        final notificationKey = '${clusterId}_${DateTime.now().day}';
        if (!shownNotifications.contains(notificationKey)) {
          await _showDangerNotification(cluster, distance, severity, reportCount);
          await _addShownNotification(notificationKey);
        }
      }
    }
  }

  /// Muestra notificación de peligro
  static Future<void> _showDangerNotification(
    Map<String, dynamic> cluster,
    double distance,
    int severity,
    int reportCount,
  ) async {
    String severityText;
    Color severityColor;
    
    switch (severity) {
      case 5:
        severityText = 'CRÍTICO';
        severityColor = Colors.red;
        break;
      case 4:
        severityText = 'ALTO';
        severityColor = Colors.orange;
        break;
      case 3:
        severityText = 'MEDIO';
        severityColor = Colors.yellow;
        break;
      case 2:
        severityText = 'BAJO';
        severityColor = Colors.green;
        break;
      default:
        severityText = 'INFORMATIVO';
        severityColor = Colors.blue;
    }

    const androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE74C3C),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🚨 ZONA DE PELIGRO',
      'Nivel $severityText - $reportCount reportes\nDistancia: ${distance.toInt()}m',
      details,
      payload: json.encode({
        'type': 'danger_zone',
        'cluster_id': cluster['id'],
        'severity': severity,
        'distance': distance,
      }),
    );

    print('🚨 [BackgroundService] Notificación de peligro enviada');
    print('   📍 Distancia: ${distance.toInt()}m');
    print('   ⚠️ Severidad: $severityText ($severity)');
    print('   📊 Reportes: $reportCount');
  }

  /// Obtiene las notificaciones ya mostradas hoy
  static Future<List<String>> _getShownNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().day.toString();
    final key = 'shown_notifications_$today';
    return prefs.getStringList(key) ?? [];
  }

  /// Agrega una notificación a la lista de mostradas
  static Future<void> _addShownNotification(String notificationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().day.toString();
    final key = 'shown_notifications_$today';
    final notifications = prefs.getStringList(key) ?? [];
    notifications.add(notificationKey);
    await prefs.setStringList(key, notifications);
  }

  /// Verifica si el servicio está ejecutándose
  static bool get isRunning => _isServiceRunning;
}
