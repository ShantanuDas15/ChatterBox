import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/channel_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/typing_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/chat/widgets/message_bubble.dart';
import 'package:frontend/screens/chat/channel_members_screen.dart';
import 'package:frontend/screens/chat/channel_settings_screen.dart';

// Make it a ConsumerStatefulWidget to use TextEditingController
class ChatScreen extends ConsumerStatefulWidget {
  final String channelId; // Channel ID parameter
  const ChatScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() {
    final content = _messageController.text;
    if (content.trim().isNotEmpty) {
      // Call the sendMessage method on our provider
      ref.read(chatProvider.notifier).sendMessage(content);
      _messageController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
    }
  }

  String _getTypingMessage(Set<String> names) {
    if (names.isEmpty) return "";
    if (names.length == 1) return "${names.first} is typing...";
    if (names.length == 2) return "${names.join(" and ")} are typing...";
    return "Several people are typing...";
  }

  // Converts a hex string to a Color
  Color? colorFromHex(String? hexColor) {
    if (hexColor == null) return null;
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsyncValue = ref.watch(chatProvider);
    final currentUserId = ref.watch(userIdProvider);
    // Watch the typing providers
    final typingNames = ref.watch(typingStatusProvider);
    // This line "activates" our listener provider
    ref.watch(typingServiceProvider);

    // Find the full Channel object for the current channel
    final currentChannel = ref
        .watch(channelsProvider)
        .value
        ?.firstWhere(
          (c) => c.id == widget.channelId,
          orElse: () => Channel(
            id: '',
            name: 'Chat',
            members: [],
            creatorId: '',
            pendingMembers: [],
          ),
        );

    // Check if the current user is the creator
    final bool isCreator = currentChannel?.creatorId == currentUserId;

    // Get the channel name
    final channelName = currentChannel?.name ?? 'Chat';

    // --- Theme Logic ---
    final Color bgColor =
        colorFromHex(currentChannel?.themeColor) ?? Colors.white;
    // Check if bg is light or dark to set text/icon color
    final Brightness brightness = ThemeData.estimateBrightnessForColor(bgColor);
    final Color fgColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    // --- NEW THEME LOGIC for chat background ---
    // We will blend the theme color with the default scaffold color.
    // This creates a light, opaque, pastel version of the theme color.
    // (e.g., 20% theme color blended over 80% white/dark background)
    final Color chatListBgColor = Color.alphaBlend(
      bgColor.withOpacity(0.20), // You can adjust this 0.20 value (20%)
      Theme.of(context).scaffoldBackgroundColor,
    );
    // ---

    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
        // --- APPLY THE COLORS ---
        backgroundColor: bgColor,
        elevation: 1,
        iconTheme: IconThemeData(color: fgColor), // Back button
        actionsIconTheme: IconThemeData(color: fgColor), // All action icons
        titleTextStyle: TextStyle(
          color: fgColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        // ---
        actions: [
          // View Members button
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              if (currentChannel != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChannelMembersScreen(channel: currentChannel),
                  ),
                );
              }
            },
          ),
          // Invite button - only visible to the creator
          if (isCreator) ...[
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _showInviteDialog(context, ref, widget.channelId);
              },
            ),
            // Admin Panel button - only visible to the creator
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                if (currentChannel != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ChannelSettingsScreen(channel: currentChannel),
                    ),
                  );
                }
              },
            ),
          ],
          // Leave button
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Channel',
            onPressed: () {
              _showLeaveDialog(context, ref, widget.channelId);
            },
          ),
        ],
      ),
      // --- APPLY THE NEW BACKGROUND COLOR ---
      backgroundColor: chatListBgColor, // Use our new pastel color
      // ---
      body: Column(
        children: [
          // --- 1. Message List ---
          Expanded(
            child: chatAsyncValue.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(
                      message: messages[index],
                      currentUserId: currentUserId,
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),

          // --- 2. Typing Indicator ---
          Container(
            // Use a slightly darker tint for the typing bar
            color: Color.alphaBlend(
              bgColor.withOpacity(0.30),
              Theme.of(context).scaffoldBackgroundColor,
            ),
            height: typingNames.isEmpty
                ? 0
                : 24, // Collapse if no one is typing
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: typingNames.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      _getTypingMessage(typingNames),
                      style: TextStyle(
                        // Use a subtle color that works on the light tint
                        color: fgColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),

          // --- 3. Message Input ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: bgColor, // Use the main theme color
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) {
                      // Send a typing event on every key press
                      ref.read(chatProvider.notifier).sendTyping();
                    },
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle: TextStyle(color: fgColor.withOpacity(0.7)),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none, // No border
                      ),
                      filled: true,
                      // Make the text field slightly transparent white/black
                      fillColor: brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.white.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(
                      color: fgColor,
                    ), // Make the typed text match
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: fgColor), // Use the fgColor
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    String channelId,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite User'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "User's Email"),
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Invite'),
              onPressed: () async {
                final email = controller.text;
                if (email.isNotEmpty) {
                  try {
                    await ref
                        .read(apiServiceProvider)
                        .inviteUserToChannel(channelId, email);
                    Navigator.of(context).pop();
                    // Show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User $email invited!')),
                    );
                  } catch (e) {
                    // Show an error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref, String channelId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Channel?'),
          content: const Text('Are you sure you want to leave this channel?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Leave'),
              onPressed: () async {
                try {
                  // 1. Call the API
                  await ref.read(apiServiceProvider).leaveChannel(channelId);

                  // 2. Close the dialog
                  Navigator.of(context).pop();

                  // 3. Clear the active channel
                  ref.read(activeChannelProvider.notifier).state = null;

                  // 4. Refresh the user's channel list
                  ref.invalidate(channelsProvider);
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to leave: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
