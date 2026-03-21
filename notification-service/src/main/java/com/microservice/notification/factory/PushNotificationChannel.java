package com.microservice.notification.factory;

import com.microservice.notification.dto.NotificationMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Push Notification Channel
 * Sends push notifications (simulated for local testing)
 */
@Slf4j
@Component
public class PushNotificationChannel implements NotificationChannel {

    @Override
    public void send(NotificationMessage message) {
        log.info("🔔 PUSH NOTIFICATION");
        log.info("   To: {}", message.getRecipient());
        log.info("   Title: {}", message.getSubject());
        log.info("   Body: {}", message.getBody());
        // In production: integrate with Firebase FCM, AWS SNS, etc.
    }

    @Override
    public String getChannelType() {
        return "PUSH";
    }
}

