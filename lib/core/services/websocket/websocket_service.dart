import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal();

  late WebSocketChannel _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    print('WebSocket conectado a $url');

    _channel.stream.listen(
      (message) {
        print('Mensaje recibido: $message');
        // Aquí puedes notificar a un ViewModel o usar streams para UI
      },
      onDone: () {
        print('Conexión cerrada');
      },
      onError: (error) {
        print('Error WebSocket: $error');
      },
    );
  }

  void send(String message) {
    _channel.sink.add(message);
  }

  void disconnect() {
    _channel.sink.close(status.goingAway);
  }
}
