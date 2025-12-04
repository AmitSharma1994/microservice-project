package com.microservice.user.exception;

/**
 * Custom exception for user already exists scenarios
 */
public class UserAlreadyExistsException extends RuntimeException {
    public UserAlreadyExistsException(String message) {
        super(message);
    }
}

