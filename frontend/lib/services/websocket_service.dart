import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  Stream<dynamic> connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    return _channel!.stream.map((event) => jsonDecode(event as String));
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void close() {
    _channel?.sink.close();
  }
}
