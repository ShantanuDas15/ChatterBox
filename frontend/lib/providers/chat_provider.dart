import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/socket_service.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/auth_state.dart';
import 'package:frontend/providers/channel_provider.dart';
import 'package:frontend/providers/user_provider.dart';

// 1. Provider for our SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.status == AuthStatus.authenticated && authState.token != null) {
    final socketService = SocketService(authState.token!);
    socketService.connect(); // Connect when the provider is created

    // Disconnect when the provider is disposed (e.g., user logs out)
    ref.onDispose(() => socketService.disconnect());
    return socketService;
  }
  // This is a dummy service, it won't be used
  return SocketService('');
});

// 2. The new ChatProvider
final chatProvider =
    StateNotifierProvider<ChatProvider, AsyncValue<List<ChatMessage>>>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final socketService = ref.watch(socketServiceProvider);
      return ChatProvider(ref, apiService, socketService);
    });

class ChatProvider extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref _ref;
  final ApiService _apiService;
  final SocketService _socketService;
  StreamSubscription? _messageSubscription;

  ChatProvider(this._ref, this._apiService, this._socketService)
    : super(const AsyncValue.loading()) {
    // Listen for new messages from the socket
    _messageSubscription = _socketService.messageStream.listen(
      _onMessageReceived,
    );

    // Listen for changes to the active channel
    _ref.listen(activeChannelProvider, (previous, next) {
      if (next != null) {
        // When channel changes, load messages and subscribe
        loadMessages(next);
        _socketService.subscribeToChannel(next);
      }
    });

    // IMPORTANT: Subscribe to the currently active channel on initialization
    final currentChannel = _ref.read(activeChannelProvider);
    if (currentChannel != null) {
      print("🎯 ChatProvider initialized with active channel: $currentChannel");
      loadMessages(currentChannel);
      _socketService.subscribeToChannel(currentChannel);
    }
  }

  // Fetch initial history from the API
  Future<void> loadMessages(String channelId) async {
    state = const AsyncValue.loading();
    try {
      final messages = await _apiService.getChannelMessages(channelId);
      state = AsyncValue.data(messages);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Add a new message received from the WebSocket
  void _onMessageReceived(ChatMessage message) {
    print("🔔 Message received in ChatProvider: ${message.content}");
    print("📍 Message channel: ${message.channelId}");

    // Only add the message if it belongs to the active channel
    final activeChannelId = _ref.read(activeChannelProvider);
    print("📍 Active channel: $activeChannelId");

    if (message.channelId == activeChannelId) {
      print("✅ Message belongs to active channel, adding to list");
      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
    } else {
      print("⏭️ Message is for a different channel, ignoring");
    }
  }

  // Send a message via the WebSocket
  Future<void> sendMessage(String content) async {
    final activeChannelId = _ref.read(activeChannelProvider);
    print("📮 ChatProvider.sendMessage called");
    print("📍 Active channel: $activeChannelId");
    print("📝 Content: $content");

    if (activeChannelId == null) {
      print("❌ No active channel, cannot send message");
      return;
    }

    // Read the name from our new provider!
    final userName = _ref.read(userNameProvider) ?? "ChatterBox User";

    _socketService.sendMessage(activeChannelId, content, userName);
  }

  // This is called by the UI
  void sendTyping() {
    final activeChannelId = _ref.read(activeChannelProvider);
    if (activeChannelId == null) return;
    _socketService.sendTyping(activeChannelId);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
