package com.microservice.order.kafka;

import com.microservice.order.event.InventoryReservedEvent;
import com.microservice.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Kafka Consumer for Inventory Events
 * Part of Saga Choreography - listens for inventory reservation results
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class InventoryEventConsumer {

    private final OrderService orderService;

    @KafkaListener(topics = "inventory-events", groupId = "order-service-group")
    public void consumeInventoryEvent(InventoryReservedEvent event) {
        log.info("Received inventory event for order: {} - Status: {}", event.getOrderId(), event.getStatus());

        try {
            if ("RESERVED".equals(event.getStatus())) {
                orderService.confirmOrder(event.getOrderId());
                log.info("Order {} confirmed after inventory reservation", event.getOrderId());
            } else if ("FAILED".equals(event.getStatus())) {
                orderService.cancelOrder(event.getOrderId(), "Inventory reservation failed: " + event.getMessage());
                log.warn("Order {} cancelled due to inventory failure", event.getOrderId());
            }
        } catch (Exception e) {
            log.error("Error processing inventory event for order {}: {}", event.getOrderId(), e.getMessage(), e);
        }
    }
}

