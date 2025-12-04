package com.microservice.user.mapper;

import com.microservice.user.dto.UserRegistrationRequest;
import com.microservice.user.dto.UserResponse;
import com.microservice.user.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

/**
 * MapStruct Mapper for User Entity and DTOs
 * Demonstrates Mapper/Adapter pattern
 */
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "active", constant = "true")
    User toEntity(UserRegistrationRequest request);

    UserResponse toResponse(User user);
}

