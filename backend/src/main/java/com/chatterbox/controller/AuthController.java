package com.chatterbox.controller;

import com.chatterbox.model.User;
import com.chatterbox.repository.UserRepository;
import com.chatterbox.service.JwtService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth") // Create a base path for auth
public class AuthController {

    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final GoogleIdTokenVerifier verifier;

    // Modified constructor to inject UserRepository and Google Verifier
    public AuthController(JwtService jwtService, UserRepository userRepository,
            @Value("${spring.security.oauth2.client.registration.google.client-id}") String googleClientId) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;

        // Initialize the Google token verifier
        this.verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                .setAudience(Collections.singletonList(googleClientId))
                .build();
    }

    // This endpoint was for testing the web flow
    @GetMapping("/success")
    public Map<String, String> authSuccess(@RequestParam("token") String token) {
        return Map.of("jwt-token", token);
    }

    // --- NEW ENDPOINT FOR FLUTTER ---
    @PostMapping("/google")
    public ResponseEntity<Map<String, String>> handleGoogleSignIn(@RequestBody Map<String, String> payload) {
        try {
            String tokenString = payload.get("idToken");
            Boolean isAccessToken = payload.get("isAccessToken") != null
                    && Boolean.parseBoolean(payload.get("isAccessToken"));

            if (tokenString == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "idToken is missing"));
            }

            String googleId, email, name;
            String photoUrl = null; // <-- ADD THIS

            if (isAccessToken) {
                // For web: Use access token to fetch user info from Google API
                System.out.println("Handling access token from web client");

                // Call Google's userinfo endpoint with the access token
                try {
                    java.net.URL url = new java.net.URL("https://www.googleapis.com/oauth2/v2/userinfo");
                    java.net.HttpURLConnection connection = (java.net.HttpURLConnection) url.openConnection();
                    connection.setRequestProperty("Authorization", "Bearer " + tokenString);

                    java.io.BufferedReader reader = new java.io.BufferedReader(
                            new java.io.InputStreamReader(connection.getInputStream()));
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        response.append(line);
                    }
                    reader.close();

                    // Parse JSON response
                    com.google.gson.Gson gson = new com.google.gson.Gson();
                    @SuppressWarnings("unchecked")
                    Map<String, Object> userInfo = gson.fromJson(response.toString(), Map.class);

                    googleId = (String) userInfo.get("id");
                    email = (String) userInfo.get("email");
                    name = (String) userInfo.get("name");
                    photoUrl = (String) userInfo.get("picture"); // <-- ADD THIS

                } catch (Exception e) {
                    e.printStackTrace();
                    return ResponseEntity.status(401).body(Map.of("error", "Invalid access token"));
                }
            } else {
                // For Android/iOS: Verify ID token
                System.out.println("Handling ID token from mobile client");

                GoogleIdToken idToken = verifier.verify(tokenString);
                if (idToken == null) {
                    return ResponseEntity.status(401).body(Map.of("error", "Invalid Google ID Token"));
                }

                GoogleIdToken.Payload gPayload = idToken.getPayload();
                googleId = gPayload.getSubject();
                email = gPayload.getEmail();
                name = (String) gPayload.get("name");
                photoUrl = (String) gPayload.get("picture"); // <-- ADD THIS
            }

            // Find or create the user in our database
            final String finalPhotoUrl = photoUrl; // <-- ADD THIS (for lambda)
            User user = userRepository.findByGoogleId(googleId)
                    .orElseGet(() -> {
                        User newUser = new User();
                        newUser.setGoogleId(googleId);
                        newUser.setEmail(email);
                        newUser.setUsername(name);
                        newUser.setPhotoUrl(finalPhotoUrl); // <-- ADD THIS
                        return userRepository.save(newUser);
                    });

            // Also update if they already exist
            if (user.getPhotoUrl() == null || !user.getPhotoUrl().equals(photoUrl)) {
                user.setPhotoUrl(photoUrl);
                userRepository.save(user);
            }

            // Generate our own internal JWT
            String internalToken = jwtService.generateTokenForUser(user);

            // Send our JWT back to the Flutter app
            return ResponseEntity.ok(Map.of("token", internalToken));

        } catch (GeneralSecurityException | IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
        }
    }

    // --- DEBUG ENDPOINT TO CHECK USER DATA ---
    @GetMapping("/debug/user/{googleId}")
    public ResponseEntity<?> debugGetUser(@PathVariable String googleId) {
        User user = userRepository.findByGoogleId(googleId).orElse(null);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "username", user.getUsername(),
                "email", user.getEmail(),
                "googleId", user.getGoogleId(),
                "photoUrl", user.getPhotoUrl() != null ? user.getPhotoUrl() : "null"));
    }

    // --- DEBUG ENDPOINT TO LIST ALL USERS ---
    @GetMapping("/debug/users")
    public ResponseEntity<?> debugGetAllUsers() {
        return ResponseEntity.ok(userRepository.findAll());
    }
}
