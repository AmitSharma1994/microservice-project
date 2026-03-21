package com.microservice.notification.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Inventory Event - consumed from inventory-events topic
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryEvent {
    private Long orderId;
    private Long productId;
    private Integer quantity;
    private String status;
    private String message;
}

