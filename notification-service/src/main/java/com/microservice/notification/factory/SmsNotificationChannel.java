package com.microservice.notification.factory;

import com.microservice.notification.dto.NotificationMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * SMS Notification Channel
 * Sends notifications via SMS (simulated for local testing)
 */
@Slf4j
@Component
public class SmsNotificationChannel implements NotificationChannel {

    @Override
    public void send(NotificationMessage message) {
        log.info("📱 SMS NOTIFICATION");
        log.info("   To: {}", message.getRecipient());
        log.info("   Message: {}", message.getBody());
        // In production: integrate with Twilio, AWS SNS, etc.
    }

    @Override
    public String getChannelType() {
        return "SMS";
    }
}

