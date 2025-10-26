import 'dart:convert';
import 'package:frontend/core/constants.dart';
import 'package:frontend/models/channel.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String _token;

  ApiService(this._token);

  // Helper method to create authenticated headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // Fetches all channels for the user
  Future<List<Channel>> getChannels() async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/api/v1/channels'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Channel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load channels');
    }
  }

  // Fetches message history for a specific channel
  Future<List<ChatMessage>> getChannelMessages(String channelId) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/messages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // Creates a new channel
  Future<Channel> createChannel(String name) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return Channel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create channel');
    }
  }

  // Invites a user to a channel by email
  Future<void> inviteUserToChannel(String channelId, String email) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/invite'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to invite user');
    }
  }

  // Fetches ALL public channels
  Future<List<Channel>> getAllPublicChannels() async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/api/v1/channels/public'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Channel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load public channels');
    }
  }

  // Joins a channel
  Future<void> joinChannel(String channelId) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/join'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to join channel');
    }
  }

  // Leaves a channel
  Future<void> leaveChannel(String channelId) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/leave'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to leave channel');
    }
  }

  // Fetches a list of User objects from a list of IDs
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/users/batch'),
      headers: _headers,
      body: jsonEncode(userIds),
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      // We need a User.fromJson model for this
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  // Removes a user from a channel
  Future<void> removeUserFromChannel(String channelId, String userId) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/remove'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove user');
    }
  }

  // Approves a user's join request
  Future<void> approveUser(String channelId, String userId) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/approve'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve user');
    }
  }

  // Denies a user's join request
  Future<void> denyUser(String channelId, String userId) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/deny'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to deny user');
    }
  }

  // Sets the theme color for a channel
  Future<void> setChannelTheme(String channelId, String colorHex) async {
    // Format as hex string (e.g., #RRGGBB)
    final String color = '#${colorHex.toUpperCase()}';

    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/v1/channels/$channelId/theme'),
      headers: _headers,
      body: jsonEncode({'color': color}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set theme');
    }
  }

  // Updates the user's username
  Future<void> updateUsername(String newName) async {
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/api/v1/users/me'),
      headers: _headers,
      body: jsonEncode({'username': newName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update username');
    }
  }
}
