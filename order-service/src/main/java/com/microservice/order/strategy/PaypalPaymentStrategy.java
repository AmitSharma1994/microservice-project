package com.microservice.order.strategy;

import com.microservice.order.entity.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * PayPal Payment Strategy - Strategy Pattern Implementation
 */
@Slf4j
@Component
public class PaypalPaymentStrategy implements PaymentStrategy {

    @Override
    public PaymentResult process(Order order) {
        log.info("Processing PayPal payment for order: {}", order.getId());

        try {
            Thread.sleep(1200);
            String transactionId = "PP-" + UUID.randomUUID().toString();
            log.info("PayPal payment successful: {}", transactionId);
            return PaymentResult.success(transactionId);
        } catch (InterruptedException e) {
            return PaymentResult.failure("Payment processing interrupted");
        }
    }

    @Override
    public String getPaymentType() {
        return "PAYPAL";
    }
}

