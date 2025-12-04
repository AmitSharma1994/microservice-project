package com.microservice.product.kafka;

import com.microservice.product.event.OrderCreatedEvent;
import com.microservice.product.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Kafka Consumer for Order Events
 * Demonstrates Observer pattern and Event-Driven Architecture
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {

    private final ProductService productService;

    @KafkaListener(topics = "order-events", groupId = "product-service-group")
    public void consumeOrderEvent(OrderCreatedEvent event) {
        log.info("Received order event: {}", event);

        try {
            if ("ORDER_CREATED".equals(event.getEventType())) {
                productService.reserveInventory(
                        event.getOrderId(),
                        event.getProductId(),
                        event.getQuantity()
                );
            }
        } catch (Exception e) {
            log.error("Error processing order event: {}", e.getMessage(), e);
        }
    }
}

