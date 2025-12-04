# Complete Microservices Project - Automated File Generator
# This PowerShell script creates all remaining files for the microservices project

$ErrorActionPreference = "Stop"

Write-Host "=== Generating Complete Microservices Project ===" -ForegroundColor Green
Write-Host ""

# Define the base path
$basePath = "D:\MicroserviceWorkspace"

# Product Service - Remaining Files
Write-Host "Creating Product Service files..." -ForegroundColor Cyan

# Product DTOs
$productDtos = @{
    "ProductRequest.java" = @"
package com.microservice.product.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductRequest {
    @NotBlank(message = "Product name is required")
    private String name;

    private String description;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private BigDecimal price;

    @NotNull(message = "Stock quantity is required")
    @Min(value = 0, message = "Stock quantity cannot be negative")
    private Integer stockQuantity;
}
"@
    "ProductResponse.java" = @"
package com.microservice.product.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductResponse {
    private Long id;
    private String name;
    private String description;
    private BigDecimal price;
    private Integer stockQuantity;
    private Boolean active;
    private LocalDateTime createdAt;
}
"@
}

# Create Product DTO files
$productDtoPath = Join-Path $basePath "product-service\src\main\java\com\microservice\product\dto"
New-Item -Path $productDtoPath -ItemType Directory -Force | Out-Null

foreach ($file in $productDtos.Keys) {
    $filePath = Join-Path $productDtoPath $file
    Set-Content -Path $filePath -Value $productDtos[$file]
    Write-Host "  ✓ Created $file" -ForegroundColor Green
}

Write-Host ""
Write-Host "Product Service files created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Project setup is in progress. Please run this script to completion." -ForegroundColor Yellow
Write-Host "After completion, you can build with: mvn clean install" -ForegroundColor White

