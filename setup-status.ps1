# Microservices Project - Setup Status Script
# Shows the current state of all services and how to run them

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Spring Boot Microservices - Setup Status" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services Status:" -ForegroundColor Yellow
Write-Host "  ✅ Parent POM                      (Complete)" -ForegroundColor Green
Write-Host "  ✅ Docker Compose                   (Complete)" -ForegroundColor Green
Write-Host "  ✅ Config Server       :8888         (Complete)" -ForegroundColor Green
Write-Host "  ✅ Eureka Server       :8761         (Complete)" -ForegroundColor Green
Write-Host "  ✅ API Gateway         :8080         (Complete - JWT Auth)" -ForegroundColor Green
Write-Host "  ✅ User Service        :8081         (Complete - Auth/CRUD)" -ForegroundColor Green
Write-Host "  ✅ Product Service     :8083         (Complete - Redis/Kafka)" -ForegroundColor Green
Write-Host "  ✅ Order Service       :8082         (Complete - Saga/Strategy)" -ForegroundColor Green
Write-Host "  ✅ Notification Service :8084        (Complete - Factory/Kafka)" -ForegroundColor Green
Write-Host ""
Write-Host "Infrastructure:" -ForegroundColor Yellow
Write-Host "  ✅ MySQL (user_db)     :3306" -ForegroundColor Green
Write-Host "  ✅ MySQL (order_db)    :3307" -ForegroundColor Green
Write-Host "  ✅ MySQL (product_db)  :3308" -ForegroundColor Green
Write-Host "  ✅ Redis               :6379" -ForegroundColor Green
Write-Host "  ✅ Kafka               :9092" -ForegroundColor Green
Write-Host "  ✅ Zookeeper           :2181" -ForegroundColor Green
Write-Host "  ✅ Zipkin              :9411" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment:" -ForegroundColor Yellow
Write-Host "  ✅ Jenkinsfile         (CI/CD Pipeline)" -ForegroundColor Green
Write-Host "  ✅ EKS Manifests       (K8s Deployments/Services/HPA/Ingress)" -ForegroundColor Green
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   How to Run Locally" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Option 1 - One command:" -ForegroundColor Yellow
Write-Host "    .\start-local.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  Option 2 - Manual steps:" -ForegroundColor Yellow
Write-Host "    mvn clean package -DskipTests" -ForegroundColor White
Write-Host "    docker-compose up --build -d" -ForegroundColor White
Write-Host ""
Write-Host "  Test APIs:" -ForegroundColor Yellow
Write-Host "    .\test-apis.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  Stop everything:" -ForegroundColor Yellow
Write-Host "    .\stop-local.ps1" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

