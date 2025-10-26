import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/channel_provider.dart';
import 'package:frontend/providers/user_provider.dart';

// 1. Create a new FutureProvider to get ALL channels
final allChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  // We need a custom method in ApiService for this
  return ref.watch(apiServiceProvider).getAllPublicChannels();
});

class BrowseChannelsScreen extends ConsumerWidget {
  const BrowseChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChannelsAsync = ref.watch(allChannelsProvider);
    // Get the user's current channels to see if they've already joined
    final myChannels = ref.watch(channelsProvider).value ?? [];
    final myChannelIds = myChannels.map((c) => c.id).toSet();

    // Get current user ID to check if they have a pending request
    final currentUserId = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Channels')),
      body: allChannelsAsync.when(
        data: (channels) => ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            final bool alreadyJoined = myChannelIds.contains(channel.id);

            // Check if user has already requested to join
            final bool alreadyRequested = channel.pendingMembers.contains(
              currentUserId,
            );

            return ListTile(
              title: Text(channel.name),
              trailing: alreadyJoined
                  ? const Icon(Icons.check, color: Colors.green)
                  : alreadyRequested
                  ? const Chip(label: Text('Requested'))
                  : ElevatedButton(
                      child: const Text('Join'),
                      onPressed: () async {
                        try {
                          // This API call now just adds to the pending list
                          await ref
                              .read(apiServiceProvider)
                              .joinChannel(channel.id);
                          // Refresh this screen to show "Requested"
                          ref.invalidate(allChannelsProvider);
                        } catch (e) {
                          // Handle error
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join channel: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
            );
          },
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
