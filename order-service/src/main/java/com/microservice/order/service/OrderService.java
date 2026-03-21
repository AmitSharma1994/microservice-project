package com.microservice.order.service;

import com.microservice.order.client.ProductServiceClient;
import com.microservice.order.client.UserServiceClient;
import com.microservice.order.dto.*;
import com.microservice.order.entity.Order;
import com.microservice.order.entity.OrderItem;
import com.microservice.order.entity.OrderStatus;
import com.microservice.order.event.OrderCancelledEvent;
import com.microservice.order.event.OrderConfirmedEvent;
import com.microservice.order.event.OrderCreatedEvent;
import com.microservice.order.exception.ResourceNotFoundException;
import com.microservice.order.kafka.OrderEventProducer;
import com.microservice.order.mapper.OrderMapper;
import com.microservice.order.repository.OrderRepository;
import com.microservice.order.strategy.PaymentContext;
import com.microservice.order.strategy.PaymentResult;
import com.microservice.order.strategy.PaymentStrategy;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Order Service - Business Logic with Saga Orchestration
 * Demonstrates Strategy pattern for payments and Saga for distributed transactions
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderMapper orderMapper;
    private final OrderEventProducer orderEventProducer;
    private final PaymentContext paymentContext;
    private final ProductServiceClient productServiceClient;
    private final UserServiceClient userServiceClient;

    /**
     * Create a new order with Saga choreography
     */
    @Transactional
    @CircuitBreaker(name = "productService", fallbackMethod = "createOrderFallback")
    public OrderResponse createOrder(OrderRequest request) {
        log.info("Creating order for user: {}", request.getUserId());

        // 1. Validate user exists via Feign
        UserResponse user = userServiceClient.getUserById(request.getUserId());
        log.info("User validated: {}", user.getUsername());

        // 2. Build order entity
        Order order = Order.builder()
                .userId(request.getUserId())
                .paymentMethod(request.getPaymentMethod())
                .status(OrderStatus.PENDING)
                .totalAmount(BigDecimal.ZERO)
                .build();

        // 3. Add items and calculate total
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (OrderItemRequest itemReq : request.getItems()) {
            ProductResponse product = productServiceClient.getProductById(itemReq.getProductId());
            log.info("Product fetched: {} - Price: {}", product.getName(), product.getPrice());

            OrderItem item = OrderItem.builder()
                    .productId(itemReq.getProductId())
                    .quantity(itemReq.getQuantity())
                    .price(product.getPrice())
                    .build();

            order.addItem(item);
            totalAmount = totalAmount.add(product.getPrice().multiply(BigDecimal.valueOf(itemReq.getQuantity())));
        }
        order.setTotalAmount(totalAmount);

        // 4. Process payment using Strategy pattern
        PaymentStrategy strategy = paymentContext.getStrategy(request.getPaymentMethod());
        PaymentResult paymentResult = strategy.process(order);

        if (!paymentResult.isSuccess()) {
            order.setStatus(OrderStatus.FAILED);
            orderRepository.save(order);
            throw new IllegalArgumentException("Payment failed: " + paymentResult.getMessage());
        }

        order.setPaymentReference(paymentResult.getTransactionId());
        Order savedOrder = orderRepository.save(order);

        // 5. Publish order events for each item (Saga choreography)
        for (OrderItem item : savedOrder.getItems()) {
            OrderCreatedEvent event = OrderCreatedEvent.builder()
                    .orderId(savedOrder.getId())
                    .productId(item.getProductId())
                    .quantity(item.getQuantity())
                    .eventType("ORDER_CREATED")
                    .build();
            orderEventProducer.publishOrderCreated(event);
        }

        log.info("Order created successfully: {}", savedOrder.getId());
        return orderMapper.toResponse(savedOrder);
    }

    /**
     * Fallback method when product service is unavailable
     */
    public OrderResponse createOrderFallback(OrderRequest request, Throwable throwable) {
        log.error("Product Service unavailable. Cannot create order: {}", throwable.getMessage());
        throw new RuntimeException("Order creation failed: Product Service is currently unavailable. Please try again later.");
    }

    /**
     * Confirm order after inventory reservation
     */
    @Transactional
    public void confirmOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", orderId));

        order.setStatus(OrderStatus.CONFIRMED);
        orderRepository.save(order);

        OrderConfirmedEvent event = OrderConfirmedEvent.builder()
                .orderId(orderId)
                .userId(order.getUserId())
                .paymentReference(order.getPaymentReference())
                .eventType("ORDER_CONFIRMED")
                .build();
        orderEventProducer.publishOrderConfirmed(event);

        log.info("Order {} confirmed", orderId);
    }

    /**
     * Cancel order (compensation in Saga)
     */
    @Transactional
    public void cancelOrder(Long orderId, String reason) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", orderId));

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        OrderCancelledEvent event = OrderCancelledEvent.builder()
                .orderId(orderId)
                .userId(order.getUserId())
                .reason(reason)
                .eventType("ORDER_CANCELLED")
                .build();
        orderEventProducer.publishOrderCancelled(event);

        log.warn("Order {} cancelled: {}", orderId, reason);
    }

    /**
     * Get order by ID
     */
    public OrderResponse getOrderById(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Order", id));
        return orderMapper.toResponse(order);
    }

    /**
     * Get orders by user ID
     */
    public List<OrderResponse> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(orderMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all orders
     */
    public List<OrderResponse> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(orderMapper::toResponse)
                .collect(Collectors.toList());
    }
}

