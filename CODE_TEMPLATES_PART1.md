# COMPLETE SOURCE CODE TEMPLATES
# Copy and create these files to complete the microservices project

## ==================== ORDER SERVICE - REMAINING FILES ====================

### File: order-service/src/main/java/com/microservice/order/dto/OrderRequest.java
```java
package com.microservice.order.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderRequest {
    
    @NotNull(message = "User ID is required")
    private Long userId;
    
    @NotEmpty(message = "Order must have at least one item")
    @Valid
    private List<OrderItemRequest> items;
    
    @NotNull(message = "Total amount is required")
    @DecimalMin(value = "0.01", message = "Total amount must be greater than 0")
    private BigDecimal totalAmount;
    
    @NotBlank(message = "Payment method is required")
    private String paymentMethod;
}
```

### File: order-service/src/main/java/com/microservice/order/dto/OrderItemRequest.java
```java
package com.microservice.order.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItemRequest {
    
    @NotNull(message = "Product ID is required")
    private Long productId;
    
    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;
    
    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private BigDecimal price;
}
```

### File: order-service/src/main/java/com/microservice/order/dto/OrderResponse.java
```java
package com.microservice.order.dto;

import com.microservice.order.entity.OrderStatus;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderResponse {
    private Long id;
    private Long userId;
    private List<OrderItemResponse> items;
    private BigDecimal totalAmount;
    private OrderStatus status;
    private String paymentMethod;
    private String paymentReference;
    private LocalDateTime createdAt;
}
```

### File: order-service/src/main/java/com/microservice/order/dto/OrderItemResponse.java
```java
package com.microservice.order.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItemResponse {
    private Long id;
    private Long productId;
    private Integer quantity;
    private BigDecimal price;
}
```

### File: order-service/src/main/java/com/microservice/order/repository/OrderRepository.java
```java
package com.microservice.order.repository;

import com.microservice.order.entity.Order;
import com.microservice.order.entity.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByUserId(Long userId);
    List<Order> findByStatus(OrderStatus status);
}
```

### File: order-service/src/main/java/com/microservice/order/client/UserServiceClient.java
```java
package com.microservice.order.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "user-service", fallback = UserServiceClientFallback.class)
public interface UserServiceClient {
    
    @GetMapping("/api/users/{id}")
    UserDto getUserById(@PathVariable Long id);
}

class UserDto {
    private Long id;
    private String username;
    private String email;
    // getters and setters
}
```

### File: order-service/src/main/java/com/microservice/order/client/UserServiceClientFallback.java
```java
package com.microservice.order.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class UserServiceClientFallback implements UserServiceClient {
    
    @Override
    public UserDto getUserById(Long id) {
        log.error("Fallback: Unable to fetch user {}", id);
        throw new RuntimeException("User service unavailable");
    }
}
```

### File: order-service/src/main/java/com/microservice/order/client/ProductServiceClient.java
```java
package com.microservice.order.client;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "product-service")
public interface ProductServiceClient {
    
    @GetMapping("/api/products/{id}")
    @CircuitBreaker(name = "productService", fallbackMethod = "getProductFallback")
    @Retry(name = "productService")
    ProductDto getProductById(@PathVariable Long id);
    
    default ProductDto getProductFallback(Long id, Exception e) {
        throw new RuntimeException("Product service unavailable: " + e.getMessage());
    }
}

class ProductDto {
    private Long id;
    private String name;
    private Integer stockQuantity;
    // getters and setters
}
```

### File: order-service/src/main/java/com/microservice/order/service/OrderService.java
```java
package com.microservice.order.service;

import com.microservice.order.client.*;
import com.microservice.order.dto.*;
import com.microservice.order.entity.*;
import com.microservice.order.event.*;
import com.microservice.order.repository.OrderRepository;
import com.microservice.order.strategy.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final UserServiceClient userServiceClient;
    private final ProductServiceClient productServiceClient;
    private final PaymentContext paymentContext;
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    private static final String ORDER_EVENTS_TOPIC = "order-events";
    
    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        log.info("Creating order for user: {}", request.getUserId());
        
        // Validate user exists
        userServiceClient.getUserById(request.getUserId());
        
        // Validate products exist and have stock
        for (OrderItemRequest item : request.getItems()) {
            ProductDto product = productServiceClient.getProductById(item.getProductId());
            if (product.getStockQuantity() < item.getQuantity()) {
                throw new RuntimeException("Insufficient stock for product: " + item.getProductId());
            }
        }
        
        // Create order
        Order order = Order.builder()
                .userId(request.getUserId())
                .totalAmount(request.getTotalAmount())
                .paymentMethod(request.getPaymentMethod())
                .status(OrderStatus.PENDING)
                .build();
        
        // Add order items
        for (OrderItemRequest itemReq : request.getItems()) {
            OrderItem item = OrderItem.builder()
                    .productId(itemReq.getProductId())
                    .quantity(itemReq.getQuantity())
                    .price(itemReq.getPrice())
                    .build();
            order.addItem(item);
        }
        
        // Process payment using Strategy Pattern
        PaymentStrategy strategy = paymentContext.getStrategy(request.getPaymentMethod());
        PaymentResult paymentResult = strategy.process(order);
        
        if (!paymentResult.isSuccess()) {
            throw new RuntimeException("Payment failed: " + paymentResult.getMessage());
        }
        
        order.setPaymentReference(paymentResult.getTransactionId());
        Order savedOrder = orderRepository.save(order);
        
        // Publish order created event (Saga Choreography)
        for (OrderItem item : savedOrder.getItems()) {
            OrderCreatedEvent event = OrderCreatedEvent.builder()
                    .orderId(savedOrder.getId())
                    .productId(item.getProductId())
                    .quantity(item.getQuantity())
                    .eventType("ORDER_CREATED")
                    .build();
            kafkaTemplate.send(ORDER_EVENTS_TOPIC, event);
        }
        
        log.info("Order created successfully: {}", savedOrder.getId());
        return toOrderResponse(savedOrder);
    }
    
    public OrderResponse getOrderById(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found: " + id));
        return toOrderResponse(order);
    }
    
    public List<OrderResponse> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(this::toOrderResponse)
                .collect(Collectors.toList());
    }
    
    @Transactional
    public void confirmOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        order.setStatus(OrderStatus.CONFIRMED);
        orderRepository.save(order);
        log.info("Order confirmed: {}", orderId);
    }
    
    @Transactional
    public void cancelOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);
        log.info("Order cancelled: {}", orderId);
    }
    
    private OrderResponse toOrderResponse(Order order) {
        List<OrderItemResponse> itemResponses = order.getItems().stream()
                .map(item -> OrderItemResponse.builder()
                        .id(item.getId())
                        .productId(item.getProductId())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());
        
        return OrderResponse.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .items(itemResponses)
                .totalAmount(order.getTotalAmount())
                .status(order.getStatus())
                .paymentMethod(order.getPaymentMethod())
                .paymentReference(order.getPaymentReference())
                .createdAt(order.getCreatedAt())
                .build();
    }
}
```

CONTINUES IN NEXT FILE DUE TO LENGTH...

