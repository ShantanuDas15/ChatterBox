package com.chatterbox.controller;

import com.chatterbox.model.User;
import com.chatterbox.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // This endpoint will get a list of user objects from a list of IDs
    @PostMapping("/batch")
    public List<User> getUsersByIds(@RequestBody List<String> userIds) {
        return userRepository.findAllByGoogleIdIn(userIds);
    }

    @PatchMapping("/me")
    public ResponseEntity<User> updateUsername(
            @RequestBody Map<String, String> payload,
            Principal principal) {

        String newUsername = payload.get("username");
        if (newUsername == null || newUsername.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        String userId = principal.getName(); // Get user's Google ID from JWT

        User user = userRepository.findByGoogleId(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Update the name and save
        user.setUsername(newUsername);
        User updatedUser = userRepository.save(user);

        return ResponseEntity.ok(updatedUser);
    }
}
