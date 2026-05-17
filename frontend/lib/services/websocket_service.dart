import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  WebSocket? _socket;
  final _controller = StreamController<dynamic>.broadcast();

  Stream<dynamic> connect(String url) {
    WebSocket.connect(url).then((socket) {
      _socket = socket;
      socket.listen(
        (event) => _controller.add(jsonDecode(event as String)),
        onError: _controller.addError,
        onDone: () => _socket = null,
      );
    }).catchError((Object error, StackTrace stackTrace) {
      _controller.addError(error, stackTrace);
      return null;
    });
    return _controller.stream;
  }

  void send(Map<String, dynamic> data) {
    _socket?.add(jsonEncode(data));
  }

  void close() {
    _socket?.close();
    _controller.close();
  }
}
