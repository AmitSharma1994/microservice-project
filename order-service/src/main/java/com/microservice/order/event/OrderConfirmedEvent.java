package com.microservice.order.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Order Confirmed Event - published when order is confirmed
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderConfirmedEvent {
    private Long orderId;
    private Long userId;
    private String paymentReference;
    private String eventType;
}

