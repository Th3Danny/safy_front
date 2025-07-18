  import 'package:flutter_local_notifications/flutter_local_notifications.dart';

  class NotificationService {
    static final NotificationService _instance = NotificationService._internal();

    factory NotificationService() => _instance;

    NotificationService._internal();

    final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    Future<void> init() async {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Puedes manejar cuando el usuario toca la notificación si quieres
        },
      );
    }

    Future<void> showNotification({
      required int id,
      required String title,
      required String body,
    }) async {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'danger_zone_channel',
        'Zonas Peligrosas',
        channelDescription: 'Notificaciones sobre zonas peligrosas cercanas',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: 'danger_zone', // opcional
      );
    }
  }
