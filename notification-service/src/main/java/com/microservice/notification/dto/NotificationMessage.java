package com.microservice.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Notification Message DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationMessage {
    private String recipient;
    private String subject;
    private String body;
    private String channel; // EMAIL, SMS, PUSH
    private String eventType;
    private Long orderId;
}

