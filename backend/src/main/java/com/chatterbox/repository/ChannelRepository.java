package com.chatterbox.repository;

import com.chatterbox.model.Channel;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ChannelRepository extends MongoRepository<Channel, String> {

    // Spring Data will auto-generate a query to find all channels
    // where the 'members' array contains the provided userId
    List<Channel> findByMembersContaining(String userId);
}
