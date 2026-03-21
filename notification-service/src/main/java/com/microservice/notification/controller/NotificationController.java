package com.microservice.notification.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Notification Controller - Health and status endpoints
 */
@Slf4j
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        return ResponseEntity.ok(Map.of(
                "service", "notification-service",
                "status", "UP",
                "timestamp", LocalDateTime.now().toString(),
                "channels", new String[]{"EMAIL", "SMS", "PUSH"}
        ));
    }
}

