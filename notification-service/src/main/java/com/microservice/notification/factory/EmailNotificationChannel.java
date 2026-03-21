package com.microservice.notification.factory;

import com.microservice.notification.dto.NotificationMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Email Notification Channel
 * Sends notifications via email (simulated for local testing)
 */
@Slf4j
@Component
public class EmailNotificationChannel implements NotificationChannel {

    @Override
    public void send(NotificationMessage message) {
        log.info("📧 EMAIL NOTIFICATION");
        log.info("   To: {}", message.getRecipient());
        log.info("   Subject: {}", message.getSubject());
        log.info("   Body: {}", message.getBody());
        // In production: use JavaMailSender to send actual emails
    }

    @Override
    public String getChannelType() {
        return "EMAIL";
    }
}

