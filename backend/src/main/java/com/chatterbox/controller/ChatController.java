package com.chatterbox.controller;

import com.chatterbox.model.ChatMessage;
import com.chatterbox.model.User;
import com.chatterbox.repository.ChatMessageRepository;
import com.chatterbox.repository.UserRepository;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.time.Instant;
import java.util.Map;

@Controller
public class ChatController {

    private final ChatMessageRepository chatMessageRepository;
    private final SimpMessagingTemplate messagingTemplate; // Used to send messages to specific topics
    private final UserRepository userRepository; // <-- ADD THIS

    public ChatController(ChatMessageRepository chatMessageRepository,
            SimpMessagingTemplate messagingTemplate,
            UserRepository userRepository) { // <-- ADD THIS
        this.chatMessageRepository = chatMessageRepository;
        this.messagingTemplate = messagingTemplate;
        this.userRepository = userRepository; // <-- ADD THIS
    }

    /**
     * Handles messages sent to "/app/chat.sendMessage/{channelId}"
     * 
     * @param channelId      The ID of the channel to send to
     * @param chatMessage    The incoming message
     * @param headerAccessor Accessor to get user info from the JWT
     */
    @MessageMapping("/chat.sendMessage/{channelId}")
    public void sendMessage(
            @DestinationVariable String channelId,
            @Payload ChatMessage chatMessage,
            SimpMessageHeaderAccessor headerAccessor) {

        // 1. Get the authenticated user from the header
        Authentication auth = (Authentication) headerAccessor.getUser();
        if (auth == null || !(auth.getPrincipal() instanceof org.springframework.security.core.userdetails.User)) {
            // User is not authenticated, ignore the message
            return;
        }

        org.springframework.security.core.userdetails.User securityUser = (org.springframework.security.core.userdetails.User) auth
                .getPrincipal();
        String googleId = securityUser.getUsername(); // This is the user's Google ID from our JWT

        // --- ADD THIS BLOCK TO FETCH USER ---
        User sender = userRepository.findByGoogleId(googleId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        System.out.println("📸 Sending message - User: " + sender.getUsername() +
                ", PhotoURL: " + sender.getPhotoUrl());
        // ---

        // 2. Populate the message object with correct info
        chatMessage.setChannelId(channelId);
        chatMessage.setSenderId(googleId);

        // Note: In a real app, you'd fetch the user's name from UserRepository
        // For simplicity, we can get it from the token claims if we add it.
        // Or, we can just rely on the client to send the senderName.
        // Let's assume the client sends the senderName for now.
        chatMessage.setSenderName(sender.getUsername()); // <-- Use name from DB
        chatMessage.setSenderPhotoUrl(sender.getPhotoUrl()); // <-- ADD THIS
        chatMessage.setTimestamp(Instant.now());

        // 3. Save the message to the database
        ChatMessage savedMessage = chatMessageRepository.save(chatMessage);

        // 4. Broadcast the saved message to the specific channel topic
        messagingTemplate.convertAndSend("/topic/channel/" + channelId, savedMessage);
    }

    /**
     * Handles typing events sent to "/app/chat.typing/{channelId}"
     * 
     * @param channelId The ID of the channel
     * @param principal The authenticated user
     */
    @MessageMapping("/chat.typing/{channelId}")
    public void handleTyping(
            @DestinationVariable String channelId,
            Principal principal) {

        // 1. Get the user from the authenticated principal
        String googleId = principal.getName();
        User sender = userRepository.findByGoogleId(googleId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. Create a payload to broadcast
        Map<String, String> payload = Map.of(
                "senderId", sender.getGoogleId(),
                "senderName", sender.getUsername());

        // 3. Broadcast to the typing topic
        // This sends to everyone *including* the sender.
        // The client will be responsible for ignoring its own typing event.
        messagingTemplate.convertAndSend("/topic/typing/" + channelId, payload);
    }
}
