# Spring Boot Microservices Project - Complete Architecture

## 🎯 Project Overview

This is a **production-ready Spring Boot Microservices Architecture** implementing industry best practices, design patterns, and distributed system concepts. Perfect for hands-on learning and portfolio demonstration.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         API Gateway                              │
│                    (Port: 8080)                                  │
│              Spring Cloud Gateway + JWT Filter                   │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├──────────────┬──────────────┬──────────────┬────────
             │              │              │              │
        ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼─────┐
        │  User   │   │  Order  │   │ Product │   │Notification│
        │ Service │   │ Service │   │ Service │   │  Service   │
        │  :8081  │   │  :8082  │   │  :8083  │   │   :8084    │
        └────┬────┘   └────┬────┘   └────┬────┘   └────┬───────┘
             │             │              │              │
             ├─MySQL───────┼─MySQL────────┼─MySQL        │
             │             │              │              │
             │             │              └──Redis       │
             │             │                             │
             └─────────────┴──── Kafka ──────────────────┘
                                   │
                          ┌────────┴────────┐
                          │   Zookeeper     │
                          └─────────────────┘

┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────┐
│  Eureka Server      │  │   Config Server     │  │   Zipkin    │
│     :8761           │  │      :8888          │  │   :9411     │
└─────────────────────┘  └─────────────────────┘  └─────────────┘
```

## 🚀 Microservices

| Service | Port | Database | Description |
|---------|------|----------|-------------|
| **Config Server** | 8888 | - | Centralized configuration management |
| **Eureka Server** | 8761 | - | Service registry and discovery |
| **API Gateway** | 8080 | - | Entry point, routing, JWT validation |
| **User Service** | 8081 | MySQL | User management, authentication, JWT generation |
| **Order Service** | 8082 | MySQL | Order management, Saga orchestration |
| **Product Service** | 8083 | MySQL + Redis | Product catalog with caching |
| **Notification Service** | 8084 | - | Event-driven notifications |

## 📋 Technology Stack

- **Java**: 17
- **Spring Boot**: 3.2.0
- **Spring Cloud**: 2023.0.0
- **Database**: MySQL 8.0
- **Cache**: Redis 7
- **Message Broker**: Kafka 3.6
- **Service Discovery**: Eureka
- **API Gateway**: Spring Cloud Gateway
- **Circuit Breaker**: Resilience4J
- **Tracing**: Zipkin
- **API Docs**: SpringDoc OpenAPI 3
- **Build Tool**: Maven
- **Containerization**: Docker & Docker Compose

## 🎨 Design Patterns Implemented

### Microservice Patterns
- ✅ **API Gateway Pattern** - Single entry point for all clients
- ✅ **Service Registry Pattern** - Dynamic service discovery with Eureka
- ✅ **Config Server Pattern** - Externalized configuration
- ✅ **Circuit Breaker Pattern** - Resilience4J for fault tolerance
- ✅ **Client-Side Load Balancing** - Spring Cloud LoadBalancer
- ✅ **Saga Pattern** - Choreography-based distributed transactions
- ✅ **CQRS** - Command-Query separation in Product Service
- ✅ **Event Sourcing** - Order state change tracking

### Code Design Patterns
- ✅ **Builder Pattern** - Entity creation (Order, User)
- ✅ **Singleton Pattern** - Spring managed beans
- ✅ **Strategy Pattern** - Payment method selection
- ✅ **Factory Pattern** - Notification channel creation
- ✅ **Observer Pattern** - Event listeners for Kafka
- ✅ **Adapter Pattern** - External API integration
- ✅ **Repository Pattern** - Data access abstraction
- ✅ **DTO + Mapper** - MapStruct for object mapping

## 🔗 Communication Patterns

### Synchronous Communication
- **REST API** with FeignClient
- Circuit Breaker protection
- Automatic retries
- Configurable timeouts

### Asynchronous Communication
- **Kafka** event streaming
- Event flow: `Order → Product → Notification`
- Choreography-based Saga

## 📁 Project Structure

```
MicroserviceWorkspace/
├── config-server/
├── eureka-server/
├── api-gateway/
├── user-service/
├── order-service/
├── product-service/
├── notification-service/
├── docker-compose.yml
├── pom.xml (parent)
└── README.md
```

## 🛠️ Prerequisites

- **JDK 17** or higher
- **Maven 3.8+**
- **Docker Desktop** (with Docker Compose)
- **Postman** or **curl** for API testing

## 🚀 Quick Start

### 1. Start Infrastructure Services

```bash
# Start all infrastructure (MySQL, Redis, Kafka, Zookeeper, Zipkin)
docker-compose up -d mysql-user mysql-order mysql-product redis kafka zookeeper zipkin

# Wait for services to be healthy (30-60 seconds)
docker-compose ps
```

### 2. Build All Microservices

```bash
# Build all services
mvn clean install

# Or build specific service
cd user-service
mvn clean install
```

### 3. Start Microservices (in order)

```bash
# Terminal 1: Config Server (must start first)
cd config-server
mvn spring-boot:run

# Terminal 2: Eureka Server (wait 30 seconds)
cd eureka-server
mvn spring-boot:run

# Terminal 3: API Gateway (wait 30 seconds)
cd api-gateway
mvn spring-boot:run

# Terminal 4: User Service
cd user-service
mvn spring-boot:run

# Terminal 5: Product Service
cd product-service
mvn spring-boot:run

# Terminal 6: Order Service
cd order-service
mvn spring-boot:run

# Terminal 7: Notification Service
cd notification-service
mvn spring-boot:run
```

### 4. Alternative: Docker Compose (All Services)

```bash
# Build all services as Docker images
mvn clean package -DskipTests

# Build Docker images
docker-compose build

# Start everything
docker-compose up -d

# View logs
docker-compose logs -f
```

## 🧪 Hands-On Practice Tasks

### Task 1: User Registration and Login

```bash
# Register a new user
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "password123",
    "role": "USER"
  }'

# Login and get JWT token
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "password123"
  }'

# Save the token from response
export TOKEN="your_jwt_token_here"
```

### Task 2: Create Products

```bash
# Create a product (requires ADMIN role)
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Laptop",
    "description": "Gaming Laptop",
    "price": 1500.00,
    "stockQuantity": 10
  }'

# Get all products (cached in Redis)
curl http://localhost:8080/api/products
```

### Task 3: Place an Order (Saga Pattern)


```bash
# Create an order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": 1,
    "items": [
      {
        "productId": 1,
        "quantity": 2,
        "price": 1500.00
      }
    ],
    "totalAmount": 3000.00,
    "paymentMethod": "CREDIT_CARD"
  }'
```

**What happens?**
1. Order Service validates user (FeignClient → User Service)
2. Order Service validates product stock (FeignClient → Product Service)
3. Order Service publishes `OrderCreatedEvent` to Kafka
4. Product Service consumes event → reserves inventory
5. Product Service publishes `InventoryReservedEvent`
6. Notification Service consumes event → sends notification

### Task 4: Observe Circuit Breaker

```bash
# Stop Product Service
# Try creating an order - Circuit breaker will open after failures

# View circuit breaker state
curl http://localhost:8082/actuator/health

# Restart Product Service - Circuit breaker will close
```

### Task 5: View Kafka Events

```bash
# Enter Kafka container
docker exec -it kafka bash

# List topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# Consume order events
kafka-console-consumer.sh --topic order-events \
  --from-beginning --bootstrap-server localhost:9092

# Consume notification events
kafka-console-consumer.sh --topic notification-events \
  --from-beginning --bootstrap-server localhost:9092
```

### Task 6: Distributed Tracing with Zipkin

1. Open browser: http://localhost:9411
2. Create an order (Task 3)
3. Search for traces in Zipkin
4. View complete request flow across services
5. Observe timing and dependencies

### Task 7: Implement Strategy Pattern - New Payment Method

**Location**: `order-service/src/main/java/com/microservice/order/strategy/`

```java
// Create new strategy
@Component
public class PaypalPaymentStrategy implements PaymentStrategy {
    @Override
    public PaymentResult process(Order order) {
        // Your PayPal implementation
        return PaymentResult.success("PAYPAL-" + UUID.randomUUID());
    }
    
    @Override
    public String getPaymentType() {
        return "PAYPAL";
    }
}
```

Test:
```bash
curl -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"paymentMethod": "PAYPAL", ...}'
```

### Task 8: Implement Factory Pattern - New Notification Channel

**Location**: `notification-service/src/main/java/com/microservice/notification/factory/`

```java
// Create new notification type
@Component
public class SlackNotificationChannel implements NotificationChannel {
    @Override
    public void send(NotificationMessage message) {
        // Your Slack implementation
    }
    
    @Override
    public String getChannelType() {
        return "SLACK";
    }
}
```

### Task 9: Test Redis Caching

```bash
# First request - hits database
curl http://localhost:8080/api/products/1

# Check Product Service logs - you'll see SQL query

# Second request - hits cache
curl http://localhost:8080/api/products/1

# Check logs - no SQL query (cached)

# Update product to invalidate cache
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Updated Laptop", "price": 1600.00}'

# Next GET will hit database again
```

### Task 10: Simulate Saga Compensation

```bash
# Reduce product stock to 0
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"stockQuantity": 0}'

# Try to order - should fail and compensate
curl -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "items": [{"productId": 1, "quantity": 5}]
  }'

# Check Kafka for OrderFailedEvent
# Check database - order status should be CANCELLED
```

## 📊 Monitoring & Observability

### Eureka Dashboard
- URL: http://localhost:8761
- View all registered services and their health

### Swagger API Documentation
- User Service: http://localhost:8081/swagger-ui.html
- Order Service: http://localhost:8082/swagger-ui.html
- Product Service: http://localhost:8083/swagger-ui.html

### Zipkin Tracing
- URL: http://localhost:9411
- View distributed traces across services

### Actuator Endpoints
```bash
# Health check
curl http://localhost:8082/actuator/health

# Metrics
curl http://localhost:8082/actuator/metrics

# Circuit breaker state
curl http://localhost:8082/actuator/circuitbreakers
```

## 🎯 Key Learning Outcomes

After completing this project, you'll understand:

1. **Microservices Architecture**: Service decomposition, independence, scalability
2. **Service Discovery**: Dynamic registration and discovery with Eureka
3. **API Gateway**: Routing, filtering, cross-cutting concerns
4. **Distributed Transactions**: Saga choreography with event sourcing
5. **Event-Driven Architecture**: Kafka producers, consumers, topics
6. **Resilience Patterns**: Circuit breakers, retries, timeouts, fallbacks
7. **Caching Strategies**: Redis integration for performance
8. **Security**: JWT authentication and authorization
9. **Observability**: Distributed tracing, logging, monitoring
10. **Design Patterns**: Strategy, Factory, Builder, Observer, Adapter, Repository
11. **Containerization**: Docker and Docker Compose orchestration
12. **REST Best Practices**: DTOs, MapStruct, validation, error handling

## 🐛 Troubleshooting

### Services won't start
```bash
# Check if ports are already in use
netstat -ano | findstr "8080"

# Kill process using port
taskkill /PID <process_id> /F

# Or change ports in application.yml
```

### Database connection errors
```bash
# Ensure MySQL containers are running
docker-compose ps

# Check MySQL logs
docker-compose logs mysql-user

# Restart MySQL containers
docker-compose restart mysql-user mysql-order mysql-product
```

### Kafka connection errors
```bash
# Kafka takes time to start (60-90 seconds)
docker-compose logs kafka

# Restart Kafka and Zookeeper
docker-compose restart zookeeper kafka
```

### Services not registering with Eureka
- Wait 30-60 seconds for initial registration
- Check Eureka dashboard: http://localhost:8761
- Verify `eureka.client.enabled=true` in application.yml
- Check service logs for connection errors

## 📚 Additional Resources

- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Resilience4J Guide](https://resilience4j.readme.io/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contributing

This is a learning project. Feel free to:
- Add new services
- Implement additional patterns
- Enhance error handling
- Add comprehensive tests
- Improve documentation

## 📄 License

This project is created for educational purposes.

---

**Happy Learning! 🚀**

*For questions or improvements, feel free to create an issue or pull request.*

