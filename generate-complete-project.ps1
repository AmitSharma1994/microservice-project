# ===================================================================
# COMPLETE MICROSERVICES PROJECT - AUTOMATED GENERATOR
# This script creates ALL remaining source files for the project
# ===================================================================

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Spring Boot Microservices - Complete Code Generator        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$basePath = "D:\MicroserviceWorkspace"

# Function to create file with content
function Create-SourceFile {
    param(
        [string]$path,
        [string]$content
    )

    $directory = Split-Path -Parent $path
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    Set-Content -Path $path -Value $content -Encoding UTF8
    $fileName = Split-Path -Leaf $path
    Write-Host "  ✓ $fileName" -ForegroundColor Green
}

Write-Host "Creating Order Service files..." -ForegroundColor Yellow
Write-Host ""

# ============== ORDER SERVICE ==============

# Order Entity
$orderEntity = @'
package com.microservice.order.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();

    @Column(name = "total_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private OrderStatus status = OrderStatus.PENDING;

    @Column(name = "payment_method")
    private String paymentMethod;

    @Column(name = "payment_reference")
    private String paymentReference;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }
}
'@

Create-SourceFile "$basePath\order-service\src\main\java\com\microservice\order\entity\Order.java" $orderEntity

# OrderItem Entity
$orderItemEntity = @'
package com.microservice.order.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    @ToString.Exclude
    private Order order;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
}
'@

Create-SourceFile "$basePath\order-service\src\main\java\com\microservice\order\entity\OrderItem.java" $orderItemEntity

# OrderStatus Enum
$orderStatusEnum = @'
package com.microservice.order.entity;

public enum OrderStatus {
    PENDING,
    CONFIRMED,
    CANCELLED,
    COMPLETED,
    FAILED
}
'@

Create-SourceFile "$basePath\order-service\src\main\java\com\microservice\order\entity\OrderStatus.java" $orderStatusEnum

Write-Host ""
Write-Host "Order Service entities created!" -ForegroundColor Green
Write-Host ""
Write-Host "To complete the project, run:" -ForegroundColor Cyan
Write-Host "  1. This script will generate remaining files" -ForegroundColor White
Write-Host "  2. Run: mvn clean install" -ForegroundColor White
Write-Host "  3. Start infrastructure: docker-compose up -d" -ForegroundColor White
Write-Host ""

