import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

/// Simple Battle WebSocket Service
class BattleWebSocketService {
  static final BattleWebSocketService _instance = BattleWebSocketService._internal();
  factory BattleWebSocketService() => _instance;
  BattleWebSocketService._internal();

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;

  /// Get WebSocket URL based on platform
  String get wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:8080/ws/battle';
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8080/ws/battle';
    } else {
      return 'ws://localhost:8080/ws/battle';
    }
  }

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  /// Connect to WebSocket
  Future<bool> connect(String userId) async {
    if (_isConnected) {
      debugPrint('⚠️ Already connected');
      debugPrint('   Instance: $hashCode');
      return true;
    }

    try {
      final url = '$wsUrl/$userId';
      debugPrint('🔌 Connecting to: $url');
      debugPrint('   Service instance: $hashCode');

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));

      _channel!.stream.listen(
            (message) {
          try {
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            debugPrint('📥 Raw WebSocket message received');
            debugPrint('   Service instance: $hashCode');
            debugPrint('   Message: $message');
            final data = json.decode(message);
            debugPrint('📨 Parsed event: ${data['event']}');
            debugPrint('📨 Full parsed data: $data');
            debugPrint('📨 Stream has listeners: ${_messageController.hasListener}');
            debugPrint('📨 Listener count: ${_messageController.stream.isBroadcast ? "broadcast" : "single"}');
            _messageController.add(data);
            debugPrint('✅ Message added to stream controller');
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          } catch (e) {
            debugPrint('❌ Error parsing message: $e');
            debugPrint('   Raw message was: $message');
          }
        },
        onError: (error) {
          debugPrint('❌ WebSocket Error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('🔌 WebSocket Disconnected');
          _isConnected = false;
        },
      );

      _isConnected = true;
      debugPrint('✅ WebSocket Connected');
      return true;

    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Create a battle room
  void createRoom({
    required String roomCode,
    required String hostName,
    required String hostAvatar,
    required String category,
    required String difficulty,
  }) {
    if (!_isConnected) {
      debugPrint('❌ Not connected');
      return;
    }

    _send({
      'event': 'create_room',
      'room_code': roomCode,
      'host_name': hostName,
      'host_avatar': hostAvatar,
      'category': category,
      'difficulty': difficulty,
    });

    debugPrint('📤 Creating room: $roomCode');
  }

  /// Join a battle room
  void joinRoom({
    required String roomCode,
    required String playerName,
    required String playerAvatar,
  }) {
    if (!_isConnected) {
      debugPrint('❌ Not connected');
      return;
    }

    _send({
      'event': 'join_room',
      'room_code': roomCode,
      'player_name': playerName,
      'player_avatar': playerAvatar,
    });

    debugPrint('📤 Joining room: $roomCode');
  }

  /// Start the game (host only)
  void startGame(String roomCode) {
    if (!_isConnected) {
      debugPrint('❌ Not connected');
      return;
    }

    _send({
      'event': 'start_game',
      'room_code': roomCode,
    });

    debugPrint('📤 Starting game: $roomCode');
  }

  /// Submit an answer
  void submitAnswer({
    required String roomCode,
    required bool isCorrect,
    required int points,
    required int questionIndex,
  }) {
    if (!_isConnected) {
      debugPrint('❌ Not connected');
      return;
    }

    _send({
      'event': 'submit_answer',
      'room_code': roomCode,
      'is_correct': isCorrect,
      'points': points,
      'question_index': questionIndex,
    });

    debugPrint('📤 Answer submitted: ${isCorrect ? "✅" : "❌"} $points pts');
  }

  /// Leave the room
  void leaveRoom(String roomCode) {
    if (!_isConnected) {
      debugPrint('⚠️ Not connected');
      return;
    }

    _send({
      'event': 'leave_room',
      'room_code': roomCode,
    });

    debugPrint('📤 Leaving room: $roomCode');
  }

  /// Send message through WebSocket
  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(json.encode(message));
    } catch (e) {
      debugPrint('❌ Send failed: $e');
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    debugPrint('🔌 Disconnecting');
    _channel?.sink.close();
    _isConnected = false;
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
