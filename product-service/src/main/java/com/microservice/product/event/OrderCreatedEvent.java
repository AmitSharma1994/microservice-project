package com.microservice.product.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Order Created Event - consumed by Product Service
 * Part of Saga Choreography pattern
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderCreatedEvent {
    private Long orderId;
    private Long productId;
    private Integer quantity;
    private String eventType;
}

