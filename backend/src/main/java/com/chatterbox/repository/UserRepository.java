package com.chatterbox.repository;

import com.chatterbox.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    // Spring Data will automatically create a query to find a user by their
    // googleId
    Optional<User> findByGoogleId(String googleId);

    // Find a user by their email address
    Optional<User> findByEmail(String email);

    // Finds all users whose Google ID is in the provided list
    List<User> findAllByGoogleIdIn(List<String> googleIds);
}
