package com.chatterbox.service;

import com.chatterbox.model.User;
import com.chatterbox.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.util.Map;

@Component
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    public OAuth2SuccessHandler(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication) throws IOException {

        OAuth2User oauthUser = (OAuth2User) authentication.getPrincipal();
        Map<String, Object> attributes = oauthUser.getAttributes();

        String googleId = oauthUser.getName();
        String email = (String) attributes.get("email");
        String name = (String) attributes.get("name");
        String photoUrl = (String) attributes.get("picture"); // <-- ADD THIS

        // Find or create the user in our database
        User user = userRepository.findByGoogleId(googleId)
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setGoogleId(googleId);
                    newUser.setEmail(email);
                    newUser.setUsername(name);
                    newUser.setPhotoUrl(photoUrl); // <-- ADD THIS
                    return userRepository.save(newUser);
                });

        // Also update if they already exist
        if (user.getPhotoUrl() == null || !user.getPhotoUrl().equals(photoUrl)) {
            user.setPhotoUrl(photoUrl);
            userRepository.save(user);
        }

        // Generate a JWT for this user
        String token = jwtService.generateToken(authentication);

        // Redirect the user with the token
        // In a real mobile app, you'd redirect to a custom scheme like
        // "chatterbox://auth?token=..."
        // For testing, we'll redirect to a simple endpoint that displays the token.
        String targetUrl = UriComponentsBuilder.fromUriString("http://localhost:8080/auth/success")
                .queryParam("token", token)
                .build().toUriString();

        getRedirectStrategy().sendRedirect(request, response, targetUrl);
    }
}
