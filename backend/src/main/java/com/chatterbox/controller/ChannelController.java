package com.chatterbox.controller;

import com.chatterbox.model.Channel;
import com.chatterbox.model.ChatMessage;
import com.chatterbox.repository.ChannelRepository;
import com.chatterbox.repository.ChatMessageRepository;
import com.chatterbox.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/channels") // Set a base path for our API
public class ChannelController {

    private final ChannelRepository channelRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;

    public ChannelController(ChannelRepository channelRepository,
            ChatMessageRepository chatMessageRepository,
            UserRepository userRepository) {
        this.channelRepository = channelRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.userRepository = userRepository;
    }

    /**
     * Creates a new channel. The creator is automatically added as a member.
     */
    @PostMapping
    public Channel createChannel(@RequestBody Map<String, String> payload, Principal principal) {
        String channelName = payload.get("name");
        String userId = principal.getName(); // Get Google ID from the JWT

        Channel newChannel = new Channel();
        newChannel.setName(channelName);
        newChannel.setMembers(List.of(userId)); // Add the creator as the first member
        newChannel.setCreatorId(userId); // Set the creator ID

        return channelRepository.save(newChannel);
    }

    /**
     * Gets all channels that the currently authenticated user is a member of.
     */
    @GetMapping
    public List<Channel> getUserChannels(Principal principal) {
        // Get the authenticated user's Google ID from the JWT
        String userId = principal.getName();

        // Use our new repository method to find only their channels
        return channelRepository.findByMembersContaining(userId);
    }

    /**
     * Gets the full message history for a single channel.
     */
    @GetMapping("/{channelId}/messages")
    public ResponseEntity<List<ChatMessage>> getChannelMessages(
            @PathVariable String channelId,
            Principal principal) {

        // TODO: Add a check here to ensure the user (principal.getName())
        // is actually a member of this channelId before returning messages.

        List<ChatMessage> messages = chatMessageRepository.findByChannelIdOrderByTimestampAsc(channelId);

        // Enrich messages with photo URLs if missing (for backward compatibility)
        for (ChatMessage message : messages) {
            if (message.getSenderPhotoUrl() == null || message.getSenderPhotoUrl().isEmpty()) {
                // Try to fetch the user and populate the photo URL
                userRepository.findByGoogleId(message.getSenderId()).ifPresent(user -> {
                    message.setSenderPhotoUrl(user.getPhotoUrl());
                    // Optionally save the updated message to avoid future lookups
                    chatMessageRepository.save(message);
                });
            }
        }

        return ResponseEntity.ok(messages);
    }

    /**
     * Invites a user to a channel by their email address.
     * Only existing channel members can invite new users.
     */
    @PostMapping("/{channelId}/invite")
    public ResponseEntity<Channel> inviteUser(
            @PathVariable String channelId,
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String userToInviteEmail = payload.get("email");
        String inviterId = principal.getName(); // The person doing the inviting

        // 1. Find the channel
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // 2. Security Check: Ensure the person inviting is the channel CREATOR
        if (!channel.getCreatorId().equals(inviterId)) {
            return ResponseEntity.status(403).body(null); // 403 Forbidden
        }

        // 3. Find the user to invite by their email
        com.chatterbox.model.User userToInvite = userRepository.findByEmail(userToInviteEmail)
                .orElseThrow(() -> new RuntimeException("User not found with that email"));

        String userIdToInvite = userToInvite.getGoogleId();

        // 4. Add the new user if they aren't already a member
        if (!channel.getMembers().contains(userIdToInvite)) {
            channel.getMembers().add(userIdToInvite);
            channelRepository.save(channel);
        }

        return ResponseEntity.ok(channel);
    }

    /**
     * Gets all public channels (regardless of membership).
     */
    @GetMapping("/public")
    public List<Channel> getAllPublicChannels() {
        // For now, "public" just means all channels.
        // You could later add a boolean "isPublic" field to your Channel model.
        return channelRepository.findAll();
    }

    /**
     * Allows a user to request to join a channel.
     * User is added to the pending members list awaiting admin approval.
     */
    @PostMapping("/{channelId}/join")
    public ResponseEntity<Channel> requestToJoinChannel(
            @PathVariable String channelId,
            Principal principal) {

        String userId = principal.getName(); // The person requesting to join

        // 1. Find the channel
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // 2. Add user to pending list IF they aren't already a member AND not already
        // pending
        if (!channel.getMembers().contains(userId) && !channel.getPendingMembers().contains(userId)) {
            channel.getPendingMembers().add(userId);
            channelRepository.save(channel);
        }

        return ResponseEntity.ok(channel);
    }

    /**
     * Approves a pending user to join the channel.
     * Only the channel creator can approve join requests.
     */
    @PostMapping("/{channelId}/approve")
    public ResponseEntity<Channel> approveUser(
            @PathVariable String channelId,
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String userIdToApprove = payload.get("userId");
        String adminId = principal.getName();

        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // Security Check: Only the creator can approve
        if (channel.getCreatorId() == null || !channel.getCreatorId().equals(adminId)) {
            return ResponseEntity.status(403).body(null); // 403 Forbidden
        }

        // Move user from pending to members
        if (channel.getPendingMembers().contains(userIdToApprove)) {
            channel.getPendingMembers().remove(userIdToApprove);

            // Add to members list if not already there
            if (!channel.getMembers().contains(userIdToApprove)) {
                channel.getMembers().add(userIdToApprove);
            }
            channelRepository.save(channel);
        }

        return ResponseEntity.ok(channel);
    }

    /**
     * Denies a pending user's request to join the channel.
     * Only the channel creator can deny join requests.
     */
    @PostMapping("/{channelId}/deny")
    public ResponseEntity<Channel> denyUser(
            @PathVariable String channelId,
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String userIdToDeny = payload.get("userId");
        String adminId = principal.getName();

        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // Security Check: Only the creator can deny
        if (channel.getCreatorId() == null || !channel.getCreatorId().equals(adminId)) {
            return ResponseEntity.status(403).body(null); // 403 Forbidden
        }

        // Just remove the user from the pending list
        channel.getPendingMembers().remove(userIdToDeny);
        channelRepository.save(channel);

        return ResponseEntity.ok(channel);
    }

    /**
     * Allows a user to leave a channel.
     */
    @PostMapping("/{channelId}/leave")
    public ResponseEntity<Channel> leaveChannel(
            @PathVariable String channelId,
            Principal principal) {

        String userId = principal.getName(); // The person leaving

        // 1. Find the channel
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // 2. Remove the user if they are a member
        if (channel.getMembers().contains(userId)) {
            channel.getMembers().remove(userId);
            channelRepository.save(channel);
        }

        // You could also add logic here to delete the channel
        // if channel.getMembers().isEmpty()

        return ResponseEntity.ok(channel);
    }

    /**
     * Removes a user from a channel. Only the channel creator can remove users.
     * The creator cannot remove themselves.
     */
    @PostMapping("/{channelId}/remove")
    public ResponseEntity<Channel> removeUser(
            @PathVariable String channelId,
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String userIdToRemove = payload.get("userId");
        String adminId = principal.getName(); // The person doing the removing

        // 1. Find the channel
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // 2. Security Check: Ensure the admin is the channel CREATOR
        if (channel.getCreatorId() == null || !channel.getCreatorId().equals(adminId)) {
            return ResponseEntity.status(403).body(null); // 403 Forbidden
        }

        // 3. Prevent creator from removing themselves
        if (channel.getCreatorId().equals(userIdToRemove)) {
            return ResponseEntity.status(400).body(null); // 400 Bad Request
        }

        // 4. Remove the user
        if (channel.getMembers().contains(userIdToRemove)) {
            channel.getMembers().remove(userIdToRemove);
            channelRepository.save(channel);
        }

        return ResponseEntity.ok(channel);
    }

    /**
     * Sets the theme color for a channel.
     * Only the channel creator can set the theme color.
     */
    @PostMapping("/{channelId}/theme")
    public ResponseEntity<Channel> setChannelTheme(
            @PathVariable String channelId,
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String color = payload.get("color"); // Expecting a hex string
        String adminId = principal.getName();

        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        // Security Check: Only the creator can set the theme
        if (channel.getCreatorId() == null || !channel.getCreatorId().equals(adminId)) {
            return ResponseEntity.status(403).body(null); // 403 Forbidden
        }

        // Set and save the new color
        channel.setThemeColor(color);
        channelRepository.save(channel);

        return ResponseEntity.ok(channel);
    }
}
