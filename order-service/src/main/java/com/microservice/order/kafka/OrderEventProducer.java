package com.microservice.order.kafka;

import com.microservice.order.event.OrderCancelledEvent;
import com.microservice.order.event.OrderConfirmedEvent;
import com.microservice.order.event.OrderCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Kafka Producer for Order Events
 * Publishes order events for Saga Choreography
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    private static final String ORDER_TOPIC = "order-events";

    public void publishOrderCreated(OrderCreatedEvent event) {
        log.info("Publishing ORDER_CREATED event for order: {}", event.getOrderId());
        kafkaTemplate.send(ORDER_TOPIC, String.valueOf(event.getOrderId()), event);
    }

    public void publishOrderConfirmed(OrderConfirmedEvent event) {
        log.info("Publishing ORDER_CONFIRMED event for order: {}", event.getOrderId());
        kafkaTemplate.send(ORDER_TOPIC, String.valueOf(event.getOrderId()), event);
    }

    public void publishOrderCancelled(OrderCancelledEvent event) {
        log.info("Publishing ORDER_CANCELLED event for order: {}", event.getOrderId());
        kafkaTemplate.send(ORDER_TOPIC, String.valueOf(event.getOrderId()), event);
    }
}

