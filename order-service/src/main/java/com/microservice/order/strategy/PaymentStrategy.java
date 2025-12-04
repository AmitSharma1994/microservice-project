package com.microservice.order.strategy;

import com.microservice.order.entity.Order;

/**
 * Payment Strategy Interface - Strategy Pattern
 * Allows different payment methods to be implemented
 */
public interface PaymentStrategy {

    PaymentResult process(Order order);

    String getPaymentType();
}

