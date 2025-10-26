package com.chatterbox.controller;

import com.chatterbox.model.User;
import com.chatterbox.repository.UserRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class HealthCheckController {

    private final UserRepository userRepository;

    // Spring automatically injects the UserRepository
    public HealthCheckController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of("status", "ok");
    }

    @GetMapping("/testdb")
    public List<User> testdb() {
        // Create a test user
        User testUser = new User();
        testUser.setUsername("Test User");
        testUser.setEmail("test@example.com");
        testUser.setGoogleId("12345-test");

        // Save the user to the database
        userRepository.save(testUser);

        // Return all users from the database
        return userRepository.findAll();
    }
}
