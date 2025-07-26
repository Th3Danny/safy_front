import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  print('[FirebaseMessagingHandler] 🔕 Mensaje en segundo plano: ${message.messageId}');
  // Aquí podrías guardar localmente o enviar logs a un servidor
}
