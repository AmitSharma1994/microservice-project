package com.microservice.notification.service;

import com.microservice.notification.dto.NotificationMessage;
import com.microservice.notification.factory.NotificationChannel;
import com.microservice.notification.factory.NotificationChannelFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Notification Service - Business logic for sending notifications
 * Uses Factory Pattern to select appropriate notification channel
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationChannelFactory channelFactory;

    public void sendNotification(NotificationMessage message) {
        log.info("Processing notification for order: {} - Type: {}", message.getOrderId(), message.getEventType());

        // Use Factory pattern to get the right channel
        NotificationChannel channel = channelFactory.getChannel(
                message.getChannel() != null ? message.getChannel() : "EMAIL"
        );
        channel.send(message);

        log.info("Notification sent successfully via {} for order: {}", channel.getChannelType(), message.getOrderId());
    }

    public void sendOrderCreatedNotification(Long orderId) {
        NotificationMessage message = NotificationMessage.builder()
                .orderId(orderId)
                .subject("Order Created - #" + orderId)
                .body("Your order #" + orderId + " has been created and is being processed.")
                .channel("EMAIL")
                .eventType("ORDER_CREATED")
                .recipient("customer@example.com")
                .build();
        sendNotification(message);
    }

    public void sendOrderConfirmedNotification(Long orderId, String paymentRef) {
        NotificationMessage message = NotificationMessage.builder()
                .orderId(orderId)
                .subject("Order Confirmed - #" + orderId)
                .body("Your order #" + orderId + " has been confirmed. Payment ref: " + paymentRef)
                .channel("EMAIL")
                .eventType("ORDER_CONFIRMED")
                .recipient("customer@example.com")
                .build();
        sendNotification(message);
    }

    public void sendOrderCancelledNotification(Long orderId, String reason) {
        NotificationMessage message = NotificationMessage.builder()
                .orderId(orderId)
                .subject("Order Cancelled - #" + orderId)
                .body("Your order #" + orderId + " has been cancelled. Reason: " + reason)
                .channel("EMAIL")
                .eventType("ORDER_CANCELLED")
                .recipient("customer@example.com")
                .build();
        sendNotification(message);
    }

    public void sendInventoryNotification(Long orderId, String status, String details) {
        NotificationMessage message = NotificationMessage.builder()
                .orderId(orderId)
                .subject("Inventory Update - Order #" + orderId)
                .body("Inventory status for order #" + orderId + ": " + status + " - " + details)
                .channel("EMAIL")
                .eventType("INVENTORY_" + status)
                .recipient("warehouse@example.com")
                .build();
        sendNotification(message);
    }
}

