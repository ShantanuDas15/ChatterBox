import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/auth_state.dart';

// Provider to hold the ID of the currently selected channel
final activeChannelProvider = StateProvider<String?>((ref) => null);

// This provider will automatically fetch the channels when the user is logged in
final channelsProvider = FutureProvider<List<Channel>>((ref) {
  // Get the apiService
  final apiService = ref.watch(apiServiceProvider);

  // Get the auth state
  final authState = ref.watch(authProvider);

  // Only fetch if we are authenticated
  if (authState.status == AuthStatus.authenticated) {
    return apiService.getChannels();
  }

  // If not authenticated, return an empty list
  return Future.value([]);
});
