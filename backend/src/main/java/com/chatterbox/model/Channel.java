package com.chatterbox.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.ArrayList;
import java.util.List;

@Document(collection = "channels")
public class Channel {
    @Id
    private String id;
    private String name;
    private List<String> members; // List of user IDs
    private String creatorId; // ID of the channel creator
    private List<String> pendingMembers = new ArrayList<>(); // List of users awaiting approval
    private String themeColor; // Theme color for the channel (e.g., "#FF0000")

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<String> getMembers() {
        return members;
    }

    public void setMembers(List<String> members) {
        this.members = members;
    }

    public String getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(String creatorId) {
        this.creatorId = creatorId;
    }

    public List<String> getPendingMembers() {
        return pendingMembers;
    }

    public void setPendingMembers(List<String> pendingMembers) {
        this.pendingMembers = pendingMembers;
    }

    public String getThemeColor() {
        return themeColor;
    }

    public void setThemeColor(String themeColor) {
        this.themeColor = themeColor;
    }
}
