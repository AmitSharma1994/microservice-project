package com.microservice.user.dto;

import com.microservice.user.entity.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for User Response
 * Implements DTO pattern to separate internal entity from API response
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {

    private Long id;
    private String username;
    private String email;
    private Role role;
    private Boolean active;
    private LocalDateTime createdAt;
}

