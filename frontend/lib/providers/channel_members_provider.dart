import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/channel_provider.dart';

// This provider gets the full User objects for the active channel
final channelMembersProvider = FutureProvider<List<User>>((ref) async {
  // Get the active channel's ID
  final activeChannelId = ref.watch(activeChannelProvider);
  if (activeChannelId == null) return [];

  // Get the full channel object from the channelsProvider
  final channels = await ref.watch(channelsProvider.future);
  final Channel? channel = channels.cast<Channel?>().firstWhere(
    (c) => c?.id == activeChannelId,
    orElse: () => null,
  );

  if (channel == null || channel.members.isEmpty) return [];

  // Get the ApiService
  final apiService = ref.watch(apiServiceProvider);

  // Fetch the user objects using the list of member IDs
  return apiService.getUsersByIds(channel.members);
});

// Provider to get pending members for a specific channel
final pendingMembersProvider = FutureProvider.autoDispose
    .family<List<User>, String>((ref, channelId) async {
      // Get the latest channels list
      final channels = await ref.watch(channelsProvider.future);
      final channel = channels.firstWhere((c) => c.id == channelId);

      if (channel.pendingMembers.isEmpty) return [];

      final apiService = ref.watch(apiServiceProvider);
      return apiService.getUsersByIds(channel.pendingMembers);
    });
