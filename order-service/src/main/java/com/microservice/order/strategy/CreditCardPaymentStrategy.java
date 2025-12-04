package com.microservice.order.strategy;

import com.microservice.order.entity.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Credit Card Payment Strategy - Strategy Pattern Implementation
 */
@Slf4j
@Component
public class CreditCardPaymentStrategy implements PaymentStrategy {

    @Override
    public PaymentResult process(Order order) {
        log.info("Processing credit card payment for order: {}", order.getId());

        // Simulate payment processing
        try {
            Thread.sleep(1000);
            String transactionId = "CC-" + UUID.randomUUID().toString();
            log.info("Credit card payment successful: {}", transactionId);
            return PaymentResult.success(transactionId);
        } catch (InterruptedException e) {
            return PaymentResult.failure("Payment processing interrupted");
        }
    }

    @Override
    public String getPaymentType() {
        return "CREDIT_CARD";
    }
}

