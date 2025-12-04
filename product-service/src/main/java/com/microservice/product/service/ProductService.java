package com.microservice.product.service;

import com.microservice.product.dto.ProductRequest;
import com.microservice.product.dto.ProductResponse;
import com.microservice.product.entity.Product;
import com.microservice.product.event.InventoryReservedEvent;
import com.microservice.product.mapper.ProductMapper;
import com.microservice.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Product Service - Business logic with Redis caching
 * Demonstrates CQRS pattern (Command Query Responsibility Segregation)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final ProductMapper productMapper;
    private final KafkaTemplate<String, Object> kafkaTemplate;

    private static final String INVENTORY_TOPIC = "inventory-events";

    // COMMAND - Write operations (no cache)
    @Transactional
    @CacheEvict(value = "products", allEntries = true)
    public ProductResponse createProduct(ProductRequest request) {
        log.info("Creating new product: {}", request.getName());
        Product product = productMapper.toEntity(request);
        Product savedProduct = productRepository.save(product);
        return productMapper.toResponse(savedProduct);
    }

    // COMMAND - Write operation
    @Transactional
    @CacheEvict(value = "products", key = "#id")
    public ProductResponse updateProduct(Long id, ProductRequest request) {
        log.info("Updating product: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found: " + id));

        productMapper.updateEntityFromRequest(request, product);
        Product updatedProduct = productRepository.save(product);
        return productMapper.toResponse(updatedProduct);
    }

    // QUERY - Read operation (cached)
    @Cacheable(value = "products", key = "#id")
    public ProductResponse getProductById(Long id) {
        log.info("Fetching product from DB: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found: " + id));
        return productMapper.toResponse(product);
    }

    // QUERY - Read operation (cached)
    @Cacheable(value = "products")
    public List<ProductResponse> getAllProducts() {
        log.info("Fetching all products from DB");
        return productRepository.findAll().stream()
                .map(productMapper::toResponse)
                .collect(Collectors.toList());
    }

    // COMMAND - Inventory management
    @Transactional
    public void reserveInventory(Long orderId, Long productId, Integer quantity) {
        log.info("Reserving inventory - Order: {}, Product: {}, Quantity: {}",
                orderId, productId, quantity);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found: " + productId));

        try {
            product.reserveStock(quantity);
            productRepository.save(product);

            // Publish success event
            InventoryReservedEvent event = InventoryReservedEvent.builder()
                    .orderId(orderId)
                    .productId(productId)
                    .quantity(quantity)
                    .status("RESERVED")
                    .message("Inventory reserved successfully")
                    .build();

            kafkaTemplate.send(INVENTORY_TOPIC, event);
            log.info("Inventory reserved successfully for order: {}", orderId);

        } catch (IllegalStateException e) {
            log.error("Failed to reserve inventory: {}", e.getMessage());

            // Publish failure event
            InventoryReservedEvent event = InventoryReservedEvent.builder()
                    .orderId(orderId)
                    .productId(productId)
                    .quantity(quantity)
                    .status("FAILED")
                    .message(e.getMessage())
                    .build();

            kafkaTemplate.send(INVENTORY_TOPIC, event);
        }
    }

    @Transactional
    @CacheEvict(value = "products", key = "#id")
    public void deleteProduct(Long id) {
        log.info("Deleting product: {}", id);
        productRepository.deleteById(id);
    }
}

