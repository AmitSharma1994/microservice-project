package com.microservice.order.strategy;

import com.microservice.order.entity.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Debit Card Payment Strategy - Strategy Pattern Implementation
 */
@Slf4j
@Component
public class DebitCardPaymentStrategy implements PaymentStrategy {

    @Override
    public PaymentResult process(Order order) {
        log.info("Processing debit card payment for order: {}", order.getId());

        try {
            Thread.sleep(800);
            String transactionId = "DC-" + UUID.randomUUID().toString();
            log.info("Debit card payment successful: {}", transactionId);
            return PaymentResult.success(transactionId);
        } catch (InterruptedException e) {
            return PaymentResult.failure("Payment processing interrupted");
        }
    }

    @Override
    public String getPaymentType() {
        return "DEBIT_CARD";
    }
}

