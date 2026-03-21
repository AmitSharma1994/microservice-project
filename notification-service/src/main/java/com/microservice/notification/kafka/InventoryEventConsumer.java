package com.microservice.notification.kafka;

import com.microservice.notification.event.InventoryEvent;
import com.microservice.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Kafka Consumer for Inventory Events
 * Listens to inventory-events topic and triggers notifications
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class InventoryEventConsumer {

    private final NotificationService notificationService;

    @KafkaListener(topics = "inventory-events", groupId = "notification-service-group")
    public void consumeInventoryEvent(InventoryEvent event) {
        log.info("Received inventory event for order: {} - Status: {}", event.getOrderId(), event.getStatus());

        try {
            notificationService.sendInventoryNotification(
                    event.getOrderId(),
                    event.getStatus(),
                    event.getMessage()
            );
        } catch (Exception e) {
            log.error("Error processing inventory event: {}", e.getMessage(), e);
        }
    }
}

