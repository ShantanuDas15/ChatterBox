import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/channel_members_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/channel_provider.dart';

class ChannelSettingsScreen extends ConsumerWidget {
  final Channel channel;
  const ChannelSettingsScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMembersProvider(channel.id));

    return Scaffold(
      appBar: AppBar(title: Text('${channel.name} Settings')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Channel Theme Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Channel Theme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          colorFromHex(channel.themeColor) ?? Colors.blue,
                    ),
                    title: const Text('Set Theme Color'),
                    onTap: () {
                      _showColorPickerDialog(context, ref, channel);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            // ---
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Join Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            pendingAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('No pending requests.'),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  shrinkWrap: true, // Use in SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildRequestTile(context, ref, users[index]);
                  },
                );
              },
              error: (e, s) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            const Divider(),
            // You can reuse the ChannelMembersScreen logic here
            // to show a list of *current* members as well.
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, WidgetRef ref, User user) {
    // Generate a consistent color for the user's avatar
    final avatarColor = _generateAvatarColor(user.username);

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(user.username),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              await ref
                  .read(apiServiceProvider)
                  .approveUser(channel.id, user.googleId);
              ref.invalidate(pendingMembersProvider(channel.id));
              ref.invalidate(channelsProvider); // So user's main list updates
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () async {
              await ref
                  .read(apiServiceProvider)
                  .denyUser(channel.id, user.googleId);
              ref.invalidate(pendingMembersProvider(channel.id));
            },
          ),
        ],
      ),
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

  // Converts a hex string to a Color
  Color? colorFromHex(String? hexColor) {
    if (hexColor == null) return null;
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return null;
  }

  // Shows the color picker dialog
  void _showColorPickerDialog(
    BuildContext context,
    WidgetRef ref,
    Channel channel,
  ) {
    Color pickerColor = colorFromHex(channel.themeColor) ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Set'),
              onPressed: () async {
                try {
                  // Convert Color(0xff123456) to "123456"
                  String hex = pickerColor.value.toRadixString(16).substring(2);
                  await ref
                      .read(apiServiceProvider)
                      .setChannelTheme(channel.id, hex);

                  // Refresh all channel data
                  ref.invalidate(channelsProvider);
                  Navigator.of(context).pop();
                } catch (e) {
                  // Handle error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to set theme: $e')),
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
}
