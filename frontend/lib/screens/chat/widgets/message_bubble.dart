import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/providers/presence_provider.dart';
import 'package:intl/intl.dart';

class MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final String? currentUserId;

  const MessageBubble({super.key, required this.message, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine if this message is from the current user
    final bool isMe = message.senderId == currentUserId;

    // --- WATCH THE PRESENCE PROVIDER ---
    // Get the set of online user IDs. Default to an empty set.
    final onlineUserIds = ref.watch(presenceStreamProvider).value ?? {};
    final bool isOnline = onlineUserIds.contains(message.senderId);

    // Debug logging
    if (onlineUserIds.isNotEmpty) {
      print("👥 MessageBubble - Online users: $onlineUserIds");
      print("👥 MessageBubble - Message sender: ${message.senderId}");
      print("👥 MessageBubble - Is online: $isOnline");
    }
    // ---

    final bubbleColor = isMe ? Colors.blue[100] : Colors.white;
    final nameColor = isMe ? Colors.blue[800] : Colors.green[800];

    // Generate a color based on sender name for consistent avatar colors
    Color avatarColor = _generateAvatarColor(message.senderName);

    // --- CREATE AVATAR WIDGET WITH ONLINE INDICATOR ---
    Widget avatar = Stack(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: avatarColor,
          child: Text(
            message.senderName.isNotEmpty
                ? message.senderName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // --- ADD THE ONLINE DOT ---
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
    // ---

    // --- BUILD THE BUBBLE CONTENT ---
    final bubbleContent = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.7, // Reduced to account for avatar
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: nameColor,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(message.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              message.content,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
    // ---

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show avatar on the left for others, not for self
          if (!isMe) ...[avatar, const SizedBox(width: 4)],

          bubbleContent, // This is the bubble you just built
          // Show avatar on the right for self, not for others
          if (isMe) ...[const SizedBox(width: 4), avatar],
        ],
      ),
    );
  }

  // Generate a consistent color for each user based on their name
  Color _generateAvatarColor(String name) {
    // Generate a hash from the name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Define a list of pleasant colors for avatars
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFD32F2F), // Red
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFF57C00), // Orange
      const Color(0xFF0097A7), // Cyan
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
      const Color(0xFFC2185B), // Pink
      const Color(0xFF00796B), // Teal
    ];

    // Use the hash to pick a color
    return colors[hash.abs() % colors.length];
  }
}
