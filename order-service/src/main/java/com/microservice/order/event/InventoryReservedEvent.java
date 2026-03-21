package com.microservice.order.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Inventory Reserved Event - consumed from Product Service
 * Part of Saga Choreography pattern
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryReservedEvent {
    private Long orderId;
    private Long productId;
    private Integer quantity;
    private String status;
    private String message;
}

