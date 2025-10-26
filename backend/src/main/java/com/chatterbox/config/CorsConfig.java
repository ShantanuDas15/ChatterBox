package com.chatterbox.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;

@Configuration
public class CorsConfig {

    @Value("${FRONTEND_URL:}")
    private String frontendUrl;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Build list of allowed origins
        List<String> allowedOrigins = new ArrayList<>(Arrays.asList(
                "http://localhost:3000",
                "http://localhost:8080",
                "http://localhost:5000",
                "http://127.0.0.1:3000",
                "http://127.0.0.1:8080"
        ));

        // Add production frontend URL if set
        if (frontendUrl != null && !frontendUrl.isEmpty()) {
            allowedOrigins.add(frontendUrl);
            System.out.println("✅ Added production frontend URL to CORS: " + frontendUrl);
        }

        configuration.setAllowedOrigins(allowedOrigins);

        // Allow all origins during development (be more restrictive in production)
        configuration.addAllowedOriginPattern("*"); // Allow all for testing

        // Allow specific HTTP methods
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

        // Allow specific headers
        configuration.setAllowedHeaders(Arrays.asList("*"));

        // Allow credentials (cookies, authorization headers)
        configuration.setAllowCredentials(true);

        // How long the browser should cache preflight responses
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}
