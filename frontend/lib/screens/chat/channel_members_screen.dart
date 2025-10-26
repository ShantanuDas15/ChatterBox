import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/providers/channel_members_provider.dart';
import 'package:frontend/providers/channel_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class ChannelMembersScreen extends ConsumerWidget {
  final Channel channel;
  const ChannelMembersScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(channelMembersProvider);
    final currentUserId = ref.watch(userIdProvider);

    // Check if the current user is the creator
    final bool isAdmin = channel.creatorId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text('${channel.name} Members')),
      body: membersAsync.when(
        data: (members) => ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final user = members[index];
            final bool isCreator = user.googleId == channel.creatorId;

            // Generate a consistent color for the user's avatar
            final avatarColor = _generateAvatarColor(user.username);

            return ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(user.username),
              subtitle: Text(isCreator ? 'Admin' : 'Member'),
              trailing:
                  (isAdmin &&
                      !isCreator) // Admin can remove, but not themselves
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        _showRemoveDialog(
                          context,
                          ref,
                          channel.id,
                          user.googleId,
                          user.username,
                        );
                      },
                    )
                  : null,
            );
          },
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    WidgetRef ref,
    String channelId,
    String userIdToRemove,
    String username,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove $username?'),
          content: Text(
            'Are you sure you want to remove this user from the channel?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
              onPressed: () async {
                try {
                  await ref
                      .read(apiServiceProvider)
                      .removeUserFromChannel(channelId, userIdToRemove);
                  Navigator.of(context).pop(); // Close dialog
                  // Refresh both member and channel lists
                  ref.invalidate(channelMembersProvider);
                  ref.invalidate(channelsProvider);
                } catch (e) {
                  // Handle error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove user: ${e.toString()}'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Generate a consistent color for each user based on their name
  Color _generateAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

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

    return colors[hash.abs() % colors.length];
  }
}
