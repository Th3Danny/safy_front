import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() => _instance;

  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Solicitar permisos en iOS
    await _messaging.requestPermission();

    // Obtener token
    final token = await _messaging.getToken();
    // Removed debug print

    // Inicializar notificaciones locales
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Configurar handlers
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Configurar background handler (definido en main.dart)
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Removed debug print

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _showLocalNotification(notification);
    }
  }

  void _onNotificationTap(RemoteMessage message) {
    // Removed debug print
    // Puedes navegar o realizar acciones aquí
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'safy_channel',
          'Notificaciones SAFY',
          channelDescription: 'Canal para notificaciones críticas de SAFY',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
