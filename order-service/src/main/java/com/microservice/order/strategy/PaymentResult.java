package com.microservice.order.strategy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Payment Result DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentResult {
    private boolean success;
    private String transactionId;
    private String message;

    public static PaymentResult success(String transactionId) {
        return PaymentResult.builder()
                .success(true)
                .transactionId(transactionId)
                .message("Payment processed successfully")
                .build();
    }

    public static PaymentResult failure(String message) {
        return PaymentResult.builder()
                .success(false)
                .message(message)
                .build();
    }
}

