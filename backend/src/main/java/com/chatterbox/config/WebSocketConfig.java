package com.chatterbox.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker // Enables WebSocket message handling, backed by a message broker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtChannelInterceptor jwtChannelInterceptor;

    public WebSocketConfig(JwtChannelInterceptor jwtChannelInterceptor) {
        this.jwtChannelInterceptor = jwtChannelInterceptor;
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Registers the "/ws" endpoint, enabling SockJS fallback options
        // This is the endpoint the Flutter client will connect to.
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS(); // Enable SockJS fallback for better compatibility

        // Also register without SockJS for raw WebSocket connections
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Defines that messages whose destination starts with "/app"
        // should be routed to @MessageMapping-annotated methods (in our controller).
        registry.setApplicationDestinationPrefixes("/app");

        // Defines that messages whose destination starts with "/topic" or "/queue"
        // should be routed to the message broker (which broadcasts to subscribed
        // clients).
        // We'll use "/topic" for public channels and "/queue" for user-specific
        // messages.
        // Note: "/topic/typing" and "/topic/presence" are included in "/topic"
        registry.enableSimpleBroker("/topic", "/queue", "/topic/typing", "/topic/presence");
    }

    // --- ADD THIS NEW METHOD ---
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Add our JWT interceptor to the inbound channel
        registration.interceptors(jwtChannelInterceptor);
    }
}
