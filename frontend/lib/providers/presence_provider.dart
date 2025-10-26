import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/chat_provider.dart';

// This provider just surfaces the presence stream from the socket service
final presenceStreamProvider = StreamProvider<Set<String>>((ref) {
  // Watch socketServiceProvider to ensure it's alive
  final socketService = ref.watch(socketServiceProvider);
  // Return its presence stream
  return socketService.presenceStream;
});
