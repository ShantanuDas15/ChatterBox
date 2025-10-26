package com.chatterbox.config;

import com.chatterbox.model.User;
import com.chatterbox.model.UserPresence;
import com.chatterbox.repository.UserRepository;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.web.socket.messaging.SessionSubscribeEvent;
import org.springframework.web.socket.messaging.SessionUnsubscribeEvent;

import java.security.Principal;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class WebSocketEventListener {

    private final SimpMessagingTemplate messagingTemplate;
    private final UserRepository userRepository;

    // Map<ChannelID, Set<UserPresence>>
    private final Map<String, Set<UserPresence>> presenceByChannel = new ConcurrentHashMap<>();
    // Map<SessionID, UserPresence>
    private final Map<String, UserPresence> userBySession = new ConcurrentHashMap<>();
    // Map<SessionID, Set<SubscriptionID>>
    private final Map<String, Set<String>> subscriptionsBySession = new ConcurrentHashMap<>();

    // Regex to extract channelId from destinations
    private final Pattern channelPattern = Pattern.compile("/topic/channel/(\\w+)");
    private final Pattern presencePattern = Pattern.compile("/topic/presence/(\\w+)");

    public WebSocketEventListener(SimpMessagingTemplate messagingTemplate, UserRepository userRepository) {
        this.messagingTemplate = messagingTemplate;
        this.userRepository = userRepository;
    }

    @EventListener
    public void handleSubscribe(SessionSubscribeEvent event) {
        SimpMessageHeaderAccessor headers = SimpMessageHeaderAccessor.wrap(event.getMessage());
        String sessionId = headers.getSessionId();
        String subscriptionId = headers.getSubscriptionId();
        String destination = headers.getDestination();
        Principal principal = headers.getUser();

        System.out.println("👂 Subscription detected - Destination: " + destination);
        System.out.println("👂 Session ID: " + sessionId);
        System.out.println("👂 Principal: " + (principal != null ? principal.getName() : "null"));

        if (principal == null || destination == null) {
            System.out.println("⚠️ Skipping - Principal or destination is null");
            return;
        }

        // Try to match against our channel topic
        Matcher matcher = channelPattern.matcher(destination);
        if (matcher.matches()) {
            String channelId = matcher.group(1);
            System.out.println("✅ Channel subscription detected: " + channelId);

            // Get user info
            UserPresence user = userBySession.computeIfAbsent(sessionId, id -> {
                User dbUser = userRepository.findByGoogleId(principal.getName()).orElseThrow();
                System.out.println("👤 User loaded: " + dbUser.getUsername() + " (ID: " + dbUser.getGoogleId() + ")");
                return new UserPresence(dbUser.getGoogleId(), dbUser.getUsername(), dbUser.getPhotoUrl());
            });

            // Store this subscription
            subscriptionsBySession.computeIfAbsent(sessionId, k -> new HashSet<>()).add(subscriptionId);

            // Add user to the channel's presence list
            Set<UserPresence> users = presenceByChannel.computeIfAbsent(channelId, k -> new HashSet<>());
            users.add(user);

            System.out.println("📊 Total users in channel " + channelId + ": " + users.size());

            // Broadcast the updated list
            broadcastPresence(channelId);
        } else {
            // Check if it's a presence subscription
            Matcher presenceMatcher = presencePattern.matcher(destination);
            if (presenceMatcher.matches()) {
                String channelId = presenceMatcher.group(1);
                System.out.println("👁️ Presence subscription detected for channel: " + channelId);

                // Send the current presence list to this subscriber immediately
                // This ensures they get the list even if they subscribed after joining the
                // channel
                broadcastPresence(channelId);
            } else {
                System.out.println("❌ Destination does not match any pattern: " + destination);
            }
        }
    }

    @EventListener
    public void handleUnsubscribe(SessionUnsubscribeEvent event) {
        // This event is less reliable than a full disconnect, but good to have
        handleDisconnect(SimpMessageHeaderAccessor.wrap(event.getMessage()));
    }

    @EventListener
    public void handleDisconnect(SessionDisconnectEvent event) {
        handleDisconnect(SimpMessageHeaderAccessor.wrap(event.getMessage()));
    }

    private void handleDisconnect(SimpMessageHeaderAccessor headers) {
        String sessionId = headers.getSessionId();
        if (sessionId == null)
            return;

        // Get the user who disconnected
        UserPresence disconnectedUser = userBySession.remove(sessionId);
        if (disconnectedUser == null)
            return;

        // Remove them from all channels they were in
        // We iterate over all channels
        presenceByChannel.forEach((channelId, users) -> {
            boolean removed = users.remove(disconnectedUser);
            // If they were in this channel, broadcast the new list
            if (removed) {
                broadcastPresence(channelId);
            }
        });

        // Clean up session data
        subscriptionsBySession.remove(sessionId);
    }

    private void broadcastPresence(String channelId) {
        Set<UserPresence> users = presenceByChannel.getOrDefault(channelId, Set.of());
        System.out.println("📢 Broadcasting presence for channel " + channelId);
        System.out.println("📢 User count: " + users.size());
        System.out.println("📢 Users: " + users);
        messagingTemplate.convertAndSend("/topic/presence/" + channelId, users);
        System.out.println("✅ Presence broadcast complete");
    }
}
