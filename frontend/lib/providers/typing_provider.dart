import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/user_provider.dart';

// This provider holds the set of names of users who are typing
final typingStatusProvider = StateProvider<Set<String>>((ref) => {});

// This helper "service" provider just exists to listen to the stream
// and manage the state of typingStatusProvider
final typingServiceProvider = Provider((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final currentUserId = ref.watch(userIdProvider);

  // A map to keep track of timers for each typing user
  final Map<String, Timer> typingTimers = {};

  // Listen to the typing stream from the socket
  final subscription = socketService.typingStream.listen((data) {
    final String senderId = data['senderId']!;
    final String senderName = data['senderName']!;

    // Don't show our own typing status
    if (senderId == currentUserId) return;

    // If we already have a timer for this user, cancel it
    typingTimers[senderName]?.cancel();

    // Add the user to the typing set
    ref
        .read(typingStatusProvider.notifier)
        .update((state) => {...state, senderName});

    // Start a new timer to remove them after 3 seconds
    typingTimers[senderName] = Timer(const Duration(seconds: 3), () {
      ref
          .read(typingStatusProvider.notifier)
          .update((state) => state.where((name) => name != senderName).toSet());
      typingTimers.remove(senderName);
    });
  });

  // When this provider is disposed (e.g., user logs out),
  // cancel the stream subscription and all timers.
  ref.onDispose(() {
    subscription.cancel();
    for (var timer in typingTimers.values) {
      timer.cancel();
    }
  });
});
