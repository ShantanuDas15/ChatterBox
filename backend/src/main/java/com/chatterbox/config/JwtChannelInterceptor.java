package com.chatterbox.config;

import com.chatterbox.service.JwtService;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.Collections;

@Component
public class JwtChannelInterceptor implements ChannelInterceptor {

    private final JwtService jwtService;

    public JwtChannelInterceptor(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        // Check if it's a CONNECT command
        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            System.out.println("🔌 WebSocket CONNECT attempt detected");

            // Look for the "Authorization" header
            String authHeader = accessor.getFirstNativeHeader("Authorization");
            System.out.println("🔑 Authorization header: " + (authHeader != null ? "Present" : "Missing"));

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String jwt = authHeader.substring(7);
                System.out.println("🎫 JWT Token received: " + jwt.substring(0, 20) + "...");

                if (jwtService.isTokenValid(jwt)) {
                    String userId = jwtService.extractUserId(jwt);
                    System.out.println("✅ Token valid for user: " + userId);

                    // Create a UserDetails object
                    UserDetails userDetails = new User(userId, "", Collections.emptyList());

                    // Create an Authentication object
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());

                    // Set the user in the STOMP header accessor
                    accessor.setUser(authToken);
                } else {
                    System.out.println("❌ Token validation failed");
                }
            } else {
                System.out.println("⚠️ No valid Authorization header found");
            }
        }
        return message;
    }
}
