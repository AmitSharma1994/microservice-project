package com.microservice.notification.kafka;

import com.microservice.notification.event.OrderEvent;
import com.microservice.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Kafka Consumer for Order Events
 * Listens to order-events topic and triggers notifications
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {

    private final NotificationService notificationService;

    @KafkaListener(topics = "order-events", groupId = "notification-service-group")
    public void consumeOrderEvent(OrderEvent event) {
        log.info("Received order event: {} for order: {}", event.getEventType(), event.getOrderId());

        try {
            switch (event.getEventType()) {
                case "ORDER_CREATED":
                    notificationService.sendOrderCreatedNotification(event.getOrderId());
                    break;
                case "ORDER_CONFIRMED":
                    notificationService.sendOrderConfirmedNotification(event.getOrderId(), event.getPaymentReference());
                    break;
                case "ORDER_CANCELLED":
                    notificationService.sendOrderCancelledNotification(event.getOrderId(), event.getReason());
                    break;
                default:
                    log.warn("Unknown order event type: {}", event.getEventType());
            }
        } catch (Exception e) {
            log.error("Error processing order event: {}", e.getMessage(), e);
        }
    }
}

