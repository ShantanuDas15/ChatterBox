package com.chatterbox.repository;

import com.chatterbox.model.ChatMessage;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface ChatMessageRepository extends MongoRepository<ChatMessage, String> {
    // Spring Data will automatically create a query to find all messages for a
    // channel
    List<ChatMessage> findByChannelIdOrderByTimestampAsc(String channelId);
}
