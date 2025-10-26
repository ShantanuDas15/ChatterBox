package com.chatterbox.config;

import com.chatterbox.service.OAuth2SuccessHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.http.HttpStatus;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

        private final OAuth2SuccessHandler oAuth2SuccessHandler;
        private final JwtAuthenticationFilter jwtAuthFilter;
        private final CorsConfigurationSource corsConfigurationSource;

        public SecurityConfig(OAuth2SuccessHandler oAuth2SuccessHandler, JwtAuthenticationFilter jwtAuthFilter,
                        CorsConfigurationSource corsConfigurationSource) {
                this.oAuth2SuccessHandler = oAuth2SuccessHandler;
                this.jwtAuthFilter = jwtAuthFilter;
                this.corsConfigurationSource = corsConfigurationSource;
        }

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
                http
                                // Enable CORS with our configuration
                                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                                .csrf(csrf -> csrf.disable()) // Disable CSRF
                                .sessionManagement(session -> session
                                                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // We use
                                                                                                         // JWT, so
                                                                                                         // no
                                                                                                         // sessions
                                .authorizeHttpRequests(auth -> auth
                                                // Allow public access to these endpoints
                                                .requestMatchers(
                                                                "/ping",
                                                                "/api/v1/auth/success", // Updated path
                                                                "/api/v1/auth/google", // Add this new endpoint
                                                                "/oauth2/**",
                                                                "/login/oauth2/code/google")
                                                .permitAll()
                                                // Allow all WebSocket connections (we'll secure this in the next phase)
                                                .requestMatchers("/ws/**").permitAll()
                                                // Protect all API v1 endpoints
                                                .requestMatchers("/api/v1/**").authenticated()
                                                // All other endpoints require authentication
                                                .anyRequest().authenticated())
                                .oauth2Login(oauth2 -> oauth2
                                                .successHandler(oAuth2SuccessHandler) // Use our custom success handler
                                )
                                // Return 401 for unauthenticated API requests instead of redirecting to login
                                .exceptionHandling(exceptions -> exceptions
                                                .authenticationEntryPoint(
                                                                new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                                // --- ADD THIS LINE ---
                                // Run our JWT filter before the standard auth filter
                                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

                return http.build();
        }
}
