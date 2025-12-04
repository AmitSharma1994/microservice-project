package com.microservice.order.strategy;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Payment Context - Strategy Pattern Context
 * Selects appropriate payment strategy based on payment type
 */
@Component
@RequiredArgsConstructor
public class PaymentContext {

    private final List<PaymentStrategy> paymentStrategies;

    public PaymentStrategy getStrategy(String paymentType) {
        Map<String, PaymentStrategy> strategyMap = paymentStrategies.stream()
                .collect(Collectors.toMap(PaymentStrategy::getPaymentType, Function.identity()));

        PaymentStrategy strategy = strategyMap.get(paymentType);
        if (strategy == null) {
            throw new IllegalArgumentException("Unsupported payment type: " + paymentType);
        }

        return strategy;
    }
}

