import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/channel.dart'; // Make sure this is imported
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/channel_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/chat/chat_screen.dart';
import 'package:frontend/screens/home/browse_channels_screen.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';

// 1. Convert to ConsumerStatefulWidget
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// 2. Create the State class
class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 3. Add a state variable to hold the search query
  String _searchQuery = "";

  // --- MODIFICATION ---
  // 1. Add a GlobalKey to control the Scaffold (and its Drawer)
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // ---

  // Show dialog to create a new channel
  void _showCreateChannelDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Channel'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Channel Name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                final name = controller.text;
                if (name.isNotEmpty) {
                  try {
                    // Call the API
                    await ref.read(apiServiceProvider).createChannel(name);
                    // Refresh the channels list
                    ref.invalidate(channelsProvider);
                    // Close the dialog
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Handle error (e.g., show a snackbar)
                    print("Failed to create channel: $e");
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- MODIFICATION ---
  // 3. I moved your sidebar code into this separate build method
  //    to keep the main build method clean.
  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final channelsAsyncValue = ref.watch(channelsProvider);
    final activeChannelId = ref.watch(activeChannelProvider);

    // Filter the list based on the search query
    final filteredChannels =
        channelsAsyncValue.valueOrNull?.where((channel) {
          return channel.name.toLowerCase().contains(_searchQuery);
        }).toList() ??
        [];

    return Container(
      width: 260, // Set a fixed width for the drawer
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F9FF), Color(0xFFEFEFF7)],
        ),
      ),
      child: Column(
        children: [
          // Header with user avatar, title and actions
          Container(
            padding: const EdgeInsets.only(
              top: 50, // Add padding for the status bar
              left: 12,
              right: 12,
              bottom: 10,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF667eea),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Channels',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF667eea)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close drawer first
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BrowseChannelsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF667eea)),
                  onPressed: () {
                    _showCreateChannelDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Channel list
          Expanded(
            child: channelsAsyncValue.when(
              data: (channels) {
                return ListView.builder(
                  itemCount: filteredChannels.length,
                  itemBuilder: (context, index) {
                    final channel = filteredChannels[index];
                    final bool isActive = channel.id == activeChannelId;
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF667eea)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.tag,
                          size: 18,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF667eea),
                        ),
                      ),
                      title: Text(
                        channel.name,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF222222)
                              : const Color(0xFF333333),
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: Colors.blue.shade100,
                      onTap: () {
                        // Set the active channel
                        ref.read(activeChannelProvider.notifier).state =
                            channel.id;
                        // --- MODIFICATION ---
                        // 4. Close the drawer after selecting a channel
                        Navigator.of(context).pop();
                        // ---
                      },
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          // Quick actions at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close drawer first
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BrowseChannelsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.explore, color: Color(0xFF667eea)),
                    label: const Text('Browse'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- END OF NEW METHOD ---

  @override
  Widget build(BuildContext context) {
    // Watch the active channel provider
    final activeChannelId = ref.watch(activeChannelProvider);

    return Scaffold(
      // --- MODIFICATION ---
      // 2. Assign the key to the Scaffold
      key: _scaffoldKey,
      // ---

      // Custom immersive AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: Container(
          padding: const EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // --- MODIFICATION ---
                // 5. Replaced the static icon with an IconButton
                //    that opens the drawer
                IconButton(
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF667eea),
                      size: 28,
                    ),
                  ),
                  onPressed: () {
                    // Use the key to open the drawer
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                // ---
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    // Refresh channels and rebuild the page
                    ref.invalidate(channelsProvider);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'ChatterBox',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Connect, Chat, Collaborate',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Expandable search
                const SizedBox(width: 18),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              hintText: 'Search channels...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            // 4. Update state when the user types
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query.toLowerCase();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                // Profile / actions
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),

                    // --- NEW PROFILE BUTTON ---
                    GestureDetector(
                      onTap: () {
                        // Use the ScaffoldKey to open the EndDrawer
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Consumer(
                        builder: (context, ref, child) {
                          final userName = ref.watch(userNameProvider);
                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF667eea),
                            child: Text(
                              userName != null && userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8), // Add some spacing
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // --- MODIFICATION ---
      // 6. Add the drawer property and pass our new _buildSidebar method
      drawer: _buildSidebar(context, ref),
      // ---

      // --- ADD THIS WIDGET ---
      endDrawer: Drawer(
        child: Consumer(
          builder: (context, ref, child) {
            // Get user info for the header
            final name = ref.watch(userNameProvider);
            final email = ref.watch(userEmailProvider);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Drawer Header
                UserAccountsDrawerHeader(
                  accountName: Text(name ?? 'ChatterBox User'),
                  accountEmail: Text(email ?? 'No email'),
                  currentAccountPicture: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      name != null && name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF667eea)),
                ),

                // Edit Profile Button
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Logout Button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the drawer
                    ref.read(authProvider.notifier).logOut();
                  },
                ),
              ],
            );
          },
        ),
      ),
      // ---

      // --- MODIFICATION ---
      // 7. Remove the Row and make the body ONLY the chat area
      body: activeChannelId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 56,
                        color: Color(0xFF667eea),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome to ChatterBox',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select or create a channel to start a conversation. You can also browse public channels.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showCreateChannelDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Channel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                219,
                                220,
                                227,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BrowseChannelsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore),
                            label: const Text('Browse Channels'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ChatScreen(channelId: activeChannelId),
      // --- END OF BODY MODIFICATION ---
    );
  }
}
