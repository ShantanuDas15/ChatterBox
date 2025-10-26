import 'dart:async';
import 'dart:convert';
import 'package:frontend/core/constants.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class SocketService {
  StompClient? _stompClient;
  final String _token;

  // StreamController to broadcast incoming messages
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  // StreamController to broadcast incoming typing events
  final _typingStreamController =
      StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get typingStream =>
      _typingStreamController.stream;

  // StreamController to broadcast presence updates
  final _presenceStreamController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get presenceStream => _presenceStreamController.stream;

  // Callback to handle unsubscribing from a previous channel
  void Function()? _channelSubscription;
  // Callback for the typing subscription
  void Function()? _typingSubscription;
  // Callback for presence subscription
  void Function()? _presenceSubscription;

  // Track connection state
  bool _isConnected = false;
  final _connectionCompleter = Completer<void>();

  SocketService(this._token);

  void connect() {
    // Replace http with ws. Use 10.0.2.2 for Android emulator
    String wsUrl = kApiBaseUrl.replaceFirst('http', 'ws') + '/ws';

    // Ensure we're using the correct protocol
    if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
      print("⚠️ Warning: Invalid WebSocket URL format: $wsUrl");
      wsUrl = 'ws://localhost:8080/ws'; // Fallback
    }

    print("🔌 Attempting to connect to WebSocket: $wsUrl");
    print(
      "🔑 Token: ${_token.isNotEmpty ? '${_token.substring(0, 20)}...' : 'EMPTY TOKEN!'}",
    );

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          print("❌ WS Error: $error");
          print("💡 Tip: Make sure the backend is running on $wsUrl");
        },
        onStompError: (StompFrame frame) {
          print("❌ STOMP Error: ${frame.body}");
          print("💡 Headers: ${frame.headers}");
        },
        onDisconnect: (StompFrame? frame) {
          print("🔌 WebSocket disconnected");
        },
        onWebSocketDone: () {
          print("✅ WebSocket connection closed cleanly");
        },
        beforeConnect: () async {
          print("⏳ Preparing to connect...");
        },
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        connectionTimeout: const Duration(seconds: 10),
        // Auto-reconnect settings
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient!.activate();
    print("🚀 WebSocket activation initiated");
  }

  void _onConnect(StompFrame frame) {
    print("✅ Socket connected successfully!");
    print("📋 Frame headers: ${frame.headers}");
    _isConnected = true;
    if (!_connectionCompleter.isCompleted) {
      _connectionCompleter.complete();
    }
  }

  Future<void> subscribeToChannel(String channelId) async {
    // Wait for connection to be established
    if (!_isConnected) {
      print("⏳ Waiting for WebSocket connection before subscribing...");
      await _connectionCompleter.future;
    }

    // Unsubscribe from the old channel, if any
    _channelSubscription?.call();
    // Unsubscribe from old channel typing topic
    _typingSubscription?.call();
    // Unsubscribe from old channel presence topic
    _presenceSubscription?.call();

    print("📡 Subscribing to channel: $channelId");

    // Subscribe to the new channel topic
    _channelSubscription = _stompClient?.subscribe(
      destination: '/topic/channel/$channelId',
      callback: (frame) {
        print("📨 Message received on channel $channelId");
        if (frame.body != null) {
          print("📝 Message body: ${frame.body}");
          // Message received! Parse it and add to our stream
          final Map<String, dynamic> jsonData = jsonDecode(frame.body!);
          final ChatMessage message = ChatMessage.fromJson(jsonData);
          _messageStreamController.add(message);
        }
      },
    );

    // Subscribe to the typing topic for this channel
    _typingSubscription = _stompClient?.subscribe(
      destination: '/topic/typing/$channelId',
      callback: (frame) {
        if (frame.body != null) {
          final Map<String, dynamic> data = jsonDecode(frame.body!);
          // Cast to the correct type and add to the stream
          _typingStreamController.add(data.cast<String, String>());
        }
      },
    );

    // Subscribe to the presence topic for this channel
    _presenceSubscription = _stompClient?.subscribe(
      destination: '/topic/presence/$channelId',
      callback: (frame) {
        print("👥 Presence update received for channel $channelId");
        if (frame.body != null) {
          print("👥 Presence data: ${frame.body}");
          final List<dynamic> userList = jsonDecode(frame.body!);
          // We only care about the IDs for our UI
          final Set<String> userIds = userList
              .map((user) => user['userId'] as String)
              .toSet();
          print("👥 Online user IDs: $userIds");
          _presenceStreamController.add(userIds);
        }
      },
    );

    print("✅ Subscribed to /topic/channel/$channelId");
    print("✅ Subscribed to /topic/typing/$channelId");
    print("✅ Subscribed to /topic/presence/$channelId");
  }

  void sendMessage(String channelId, String content, String senderName) {
    // Get the Google ID from the token (we need to parse it)
    // For this demo, we'll just send the name.
    // In a real app, you'd pass the senderId.

    final body = jsonEncode({
      'content': content,
      'senderName': senderName, // The backend will fill in the senderId
    });

    print("📤 Sending message to channel $channelId");
    print("📝 Message content: $content");

    _stompClient?.send(
      destination: '/app/chat.sendMessage/$channelId',
      body: body,
      headers: {'Content-Type': 'application/json'},
    );

    print("✅ Message sent to /app/chat.sendMessage/$channelId");
  }

  void sendTyping(String channelId) {
    _stompClient?.send(
      destination: '/app/chat.typing/$channelId',
      body: jsonEncode(
        {},
      ), // Backend gets user from Principal, body can be empty
      headers: {'Content-Type': 'application/json'},
    );
  }

  void disconnect() {
    _channelSubscription?.call();
    _typingSubscription?.call();
    _presenceSubscription?.call();
    _stompClient?.deactivate();
    _messageStreamController.close();
    _typingStreamController.close();
    _presenceStreamController.close();
    _isConnected = false;
    print("Socket disconnected");
  }
}
