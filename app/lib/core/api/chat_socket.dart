import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'api_constants.dart';

/// WebSocket-клиент для real-time сообщений в чате.
///
/// Автоматически переподключается при разрыве (экспоненциальная задержка).
class ChatSocket {
  ChatSocket({required this.chatId, required this.token});

  final int chatId;
  final String token;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _attempt = 0;

  final _events = StreamController<SocketEvent>.broadcast();
  final _connection = StreamController<SocketConnectionState>.broadcast();

  Stream<SocketEvent> get events => _events.stream;
  Stream<SocketConnectionState> get connection => _connection.stream;

  void connect() {
    if (_disposed) return;
    final uri = Uri.parse('${ApiConstants.chatSocket(chatId)}?token=$token');
    _connection.add(SocketConnectionState.connecting);
    try {
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      _sub = ch.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
      ch.ready.then((_) {
        if (!_disposed) {
          _attempt = 0;
          _connection.add(SocketConnectionState.connected);
        }
      }).catchError((_) {
        if (!_disposed) {
          _connection.add(SocketConnectionState.disconnected);
          _scheduleReconnect();
        }
      });
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> payload) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode(payload));
  }

  void sendTyping(bool isTyping) => send({'type': 'typing', 'is_typing': isTyping});
  void sendRead(int messageId) => send({'type': 'read', 'message_id': messageId});
  void sendMessage({required String content, required String messageType}) {
    send({
      'type': 'message',
      'content': content,
      'message_type': messageType,
    });
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      _events.add(SocketEvent.fromJson(data));
    } catch (_) {
      // Игнорируем нераспаршенные сообщения.
    }
  }

  void _onError(Object _, [StackTrace? __]) {
    _connection.add(SocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    _connection.add(SocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final delaySeconds = (1 << _attempt).clamp(1, 30);
    _attempt = (_attempt + 1).clamp(0, 5);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close(ws_status.normalClosure);
    await _events.close();
    await _connection.close();
  }
}

enum SocketConnectionState { idle, connecting, connected, disconnected }

class SocketEvent {
  SocketEvent({
    required this.type,
    required this.payload,
  });

  factory SocketEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'unknown';
    return SocketEvent(type: type, payload: json);
  }

  final String type;
  final Map<String, dynamic> payload;

  static const message = 'message';
  static const typing = 'typing';
  static const read = 'read';
  static const online = 'online';
  static const offline = 'offline';
}
