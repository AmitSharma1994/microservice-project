package com.microservice.gateway.config;

import com.microservice.gateway.filter.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Gateway Configuration
 * Defines routes with JWT authentication filter
 */
@Configuration
public class GatewayConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("user-service", r -> r
                        .path("/api/users/**")
                        .filters(f -> f.filter(jwtAuthenticationFilter))
                        .uri("lb://user-service"))
                .route("product-service", r -> r
                        .path("/api/products/**")
                        .filters(f -> f.filter(jwtAuthenticationFilter))
                        .uri("lb://product-service"))
                .route("order-service", r -> r
                        .path("/api/orders/**")
                        .filters(f -> f.filter(jwtAuthenticationFilter))
                        .uri("lb://order-service"))
                .build();
    }
}

