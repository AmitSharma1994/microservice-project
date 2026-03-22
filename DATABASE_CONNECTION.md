# 🗄️ Database Connection Guide

This guide explains how to connect to the MySQL databases and Redis cache that are running as Docker containers in this microservice project.

---

## 📦 Running Databases Overview

| Container | Database | Host (Local) | Port | Service User | Password |
|-----------|----------|--------------|------|--------------|----------|
| `mysql-user` | `user_db` | `127.0.0.1` | `3306` | `userservice` | `userservice123` |
| `mysql-order` | `order_db` | `127.0.0.1` | `3307` | `orderservice` | `orderservice123` |
| `mysql-product` | `product_db` | `127.0.0.1` | `3308` | `productservice` | `productservice123` |
| `redis` | *(cache)* | `127.0.0.1` | `6379` | *(no auth)* | *(none)* |

> 🔑 **Root credentials** (admin access) — applies to **all** MySQL containers:
> - Username: `root`
> - Password: `root`

---

## 🚀 Step 1 — Start the Database Containers

Before connecting, make sure the containers are up and running:

```powershell
cd D:\WSMicroservice\microservice-project

# Start only the database containers
docker-compose up -d mysql-user mysql-order mysql-product redis

# Verify they are running
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
```

You should see output similar to:

```
NAMES            PORTS                               STATUS
mysql-user       0.0.0.0:3306->3306/tcp              Up (healthy)
mysql-order      0.0.0.0:3307->3306/tcp              Up (healthy)
mysql-product    0.0.0.0:3308->3306/tcp              Up (healthy)
redis            0.0.0.0:6379->6379/tcp              Up (healthy)
```

---

## 🔌 Step 2 — Connect Using MySQL Workbench

### Add a New Connection

1. Open **MySQL Workbench**
2. On the Home screen, click the **`+`** icon next to *"MySQL Connections"*
3. Fill in the connection details for each database (see below)
4. Click **"Store in Vault..."** to save the password
5. Click **"Test Connection"** — you should see ✅ *"Successfully made the MySQL connection"*
6. Click **OK** to save

---

### 🔵 Connection 1 — User Service Database

| Field | Value |
|-------|-------|
| **Connection Name** | `Docker - User DB` |
| **Connection Method** | `Standard (TCP/IP)` |
| **Hostname** | `127.0.0.1` |
| **Port** | `3306` |
| **Username** | `userservice` |
| **Password** | `userservice123` |
| **Default Schema** | `user_db` |

---

### 🟠 Connection 2 — Order Service Database

| Field | Value |
|-------|-------|
| **Connection Name** | `Docker - Order DB` |
| **Connection Method** | `Standard (TCP/IP)` |
| **Hostname** | `127.0.0.1` |
| **Port** | `3307` |
| **Username** | `orderservice` |
| **Password** | `orderservice123` |
| **Default Schema** | `order_db` |

---

### 🟢 Connection 3 — Product Service Database

| Field | Value |
|-------|-------|
| **Connection Name** | `Docker - Product DB` |
| **Connection Method** | `Standard (TCP/IP)` |
| **Hostname** | `127.0.0.1` |
| **Port** | `3308` |
| **Username** | `productservice` |
| **Password** | `productservice123` |
| **Default Schema** | `product_db` |

---

## 🔴 Step 3 — Connect to Redis Cache

The **Product Service** uses Redis for caching (configured in `CacheConfig.java`).

### Using Redis CLI (via Docker)

```powershell
# Open Redis CLI inside the container
docker exec -it redis redis-cli

# Test connection
127.0.0.1:6379> PING
# Response: PONG

# List all cached keys
127.0.0.1:6379> KEYS *

# Get a specific cached value
127.0.0.1:6379> GET <key-name>

# Check TTL of a key (cache expiry — set to 10 minutes in CacheConfig.java)
127.0.0.1:6379> TTL <key-name>
```

### Using Redis Desktop Manager / RedisInsight (GUI Tool)

1. Download [RedisInsight](https://redis.com/redis-enterprise/redis-insight/) (free GUI)
2. Click **"+ Add Redis Database"**
3. Fill in:

| Field | Value |
|-------|-------|
| **Host** | `127.0.0.1` |
| **Port** | `6379` |
| **Name** | `Docker - Redis Cache` |
| **Password** | *(leave empty)* |

4. Click **"Add Redis Database"**

---

## 🧪 Step 4 — Verify Data via Command Line

### MySQL Quick Checks

```powershell
# Check tables in user_db
docker exec -it mysql-user mysql -u userservice -puserservice123 user_db -e "SHOW TABLES;"

# Check tables in order_db
docker exec -it mysql-order mysql -u orderservice -porderservice123 order_db -e "SHOW TABLES;"

# Check tables in product_db
docker exec -it mysql-product mysql -u productservice -pproductservice123 product_db -e "SHOW TABLES;"

# Query products (example)
docker exec -it mysql-product mysql -u productservice -pproductservice123 product_db -e "SELECT * FROM products LIMIT 10;"

# Query users (example)
docker exec -it mysql-user mysql -u userservice -puserservice123 user_db -e "SELECT id, username, email FROM users LIMIT 10;"

# Query orders (example)
docker exec -it mysql-order mysql -u orderservice -porderservice123 order_db -e "SELECT * FROM orders LIMIT 10;"
```

### Redis Quick Checks

```powershell
# Ping Redis
docker exec -it redis redis-cli PING

# List all keys
docker exec -it redis redis-cli KEYS "*"

# Monitor real-time Redis commands
docker exec -it redis redis-cli MONITOR
```

---

## 🔗 Spring Boot Application Database Configuration

The services connect to the databases using the following JDBC URLs (set in `docker-compose.yml`):

| Service | JDBC URL | Used In |
|---------|----------|---------|
| User Service | `jdbc:mysql://mysql-user:3306/user_db` | `user-service` container |
| Order Service | `jdbc:mysql://mysql-order:3306/order_db` | `order-service` container |
| Product Service | `jdbc:mysql://mysql-product:3306/product_db` | `product-service` container |

> ⚠️ **Note:** Inside Docker containers, services communicate using **container names** (e.g., `mysql-user`) as hostnames. From your local machine (MySQL Workbench), always use `127.0.0.1`.

### Redis Configuration (Product Service — `CacheConfig.java`)

```java
// Cache TTL: 10 minutes (configured in CacheConfig.java)
// Redis Host (Docker): redis:6379
// Redis Host (Local):  127.0.0.1:6379
```

---

## ❌ Troubleshooting

### ❓ "Can't connect to MySQL server on '127.0.0.1'"
The container is not running. Start it with:
```powershell
docker-compose up -d mysql-user mysql-order mysql-product
```

### ❓ "Access denied for user"
Use `root` / `root` for admin access, or check the credentials table at the top.

### ❓ Port already in use
Check if something else is using the port:
```powershell
netstat -ano | findstr :3306
netstat -ano | findstr :3307
netstat -ano | findstr :3308
```

### ❓ Container is unhealthy / restarting
Check container logs:
```powershell
docker logs mysql-user
docker logs mysql-order
docker logs mysql-product
docker logs redis
```

### ❓ Data is gone after restart
Data is persisted in Docker volumes. Check volumes:
```powershell
docker volume ls
# Expected: mysql-user-data, mysql-order-data, mysql-product-data, redis-data
```

To remove all data and start fresh (⚠️ destructive):
```powershell
docker-compose down -v
docker-compose up -d mysql-user mysql-order mysql-product redis
```

---

## 📊 All Docker Container Ports Reference

| Service | Container Name | Local Port | Container Port |
|---------|---------------|------------|----------------|
| MySQL (User) | `mysql-user` | `3306` | `3306` |
| MySQL (Order) | `mysql-order` | `3307` | `3306` |
| MySQL (Product) | `mysql-product` | `3308` | `3306` |
| Redis | `redis` | `6379` | `6379` |
| Kafka | `kafka` | `9092` | `9092` |
| Zookeeper | `zookeeper` | `2181` | `2181` |
| Zipkin | `zipkin` | `9411` | `9411` |
| Config Server | `config-server` | `8888` | `8888` |
| Eureka Server | `eureka-server` | `8761` | `8761` |
| API Gateway | `api-gateway` | `8080` | `8080` |
| User Service | `user-service` | `8081` | `8081` |
| Order Service | `order-service` | `8082` | `8082` |
| Product Service | `product-service` | `8083` | `8083` |
| Notification Service | `notification-service` | `8084` | `8084` |

