package com.chatterbox.model;

import java.util.Objects;

// A DTO (Data Transfer Object) for presence info
public class UserPresence {
    private String userId;
    private String username;
    private String photoUrl;

    public UserPresence(String userId, String username, String photoUrl) {
        this.userId = userId;
        this.username = username;
        this.photoUrl = photoUrl;
    }

    // Getters
    public String getUserId() {
        return userId;
    }

    public String getUsername() {
        return username;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    // Implement equals() and hashCode() so we can use this in a Set
    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;
        UserPresence that = (UserPresence) o;
        return Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId);
    }
}
