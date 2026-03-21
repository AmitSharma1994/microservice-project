package com.microservice.order.client;

import com.microservice.order.dto.ProductResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * Fallback for Product Service Feign Client
 * Provides graceful degradation when Product Service is unavailable
 */
@Slf4j
@Component
public class ProductServiceClientFallback implements ProductServiceClient {

    @Override
    public ProductResponse getProductById(Long id) {
        log.warn("Product Service is unavailable. Returning fallback for product ID: {}", id);
        return ProductResponse.builder()
                .id(id)
                .name("unavailable")
                .price(BigDecimal.ZERO)
                .stockQuantity(0)
                .active(false)
                .build();
    }
}

