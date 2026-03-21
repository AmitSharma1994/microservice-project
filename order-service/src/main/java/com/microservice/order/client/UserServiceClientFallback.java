package com.microservice.order.client;

import com.microservice.order.dto.UserResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Fallback for User Service Feign Client
 * Provides graceful degradation when User Service is unavailable
 */
@Slf4j
@Component
public class UserServiceClientFallback implements UserServiceClient {

    @Override
    public UserResponse getUserById(Long id) {
        log.warn("User Service is unavailable. Returning fallback for user ID: {}", id);
        return UserResponse.builder()
                .id(id)
                .username("unknown")
                .email("unknown")
                .active(false)
                .build();
    }
}

