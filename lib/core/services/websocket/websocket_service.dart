import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal();

  late WebSocketChannel _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    // Removed debug print

    _channel.stream.listen(
      (message) {
        // Removed debug print
        // Aquí puedes notificar a un ViewModel o usar streams para UI
      },
      onDone: () {
        // Removed debug print
      },
      onError: (error) {
        // Removed debug print
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
