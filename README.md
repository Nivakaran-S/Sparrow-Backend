# Logistics Microservices with Keycloak Authentication

This project provides a complete microservices architecture for a logistics system with Keycloak authentication and authorization.

## Architecture Overview

- **API Gateway**: Spring Boot Gateway with Keycloak integration
- **User Service**: User management and authentication
- **Parcel Service**: Parcel management
- **Tracking Service**: Package tracking
- **Notification Service**: Notification management
- **Location Service**: Location and routing
- **Chatbot Service**: AI-powered customer service (Python)
- **ETA Service**: Estimated time of arrival calculations (Python)
- **Keycloak**: Authentication and authorization server
- **PostgreSQL**: Database for Keycloak

## Prerequisites

- Docker and Docker Compose
- Java 17+ (for Spring Boot services)
- Python 3.9+ (for Python services)
- Maven 3.6+ (for building Spring Boot services)

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd logistics-microservices
```

### 2. Environment Configuration

Copy the `.env` file and update with your actual values:

```bash
cp .env.example .env
```

Update the following values in `.env`:
- `MONGO_URI`: Your MongoDB connection string
- `KAFKA_BROKER`: Your Confluent Cloud Kafka broker
- `CONFLUENT_API_KEY` and `CONFLUENT_API_SECRET`: Your Confluent Cloud credentials
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`: Your Redis configuration
- `KEYCLOAK_CLIENT_SECRET`: Generate a secure secret for Keycloak client

### 3. Start the Services

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

### 4. Setup Keycloak (First Time Only)

Wait for Keycloak to be ready, then run the setup script:

```bash
# Make script executable
chmod +x scripts/setup-keycloak.sh

# Run setup script
./scripts/setup-keycloak.sh
```

### 5. Verify Setup

1. **Keycloak Admin Console**: http://localhost:8080
   - Username: `admin`
   - Password: `admin`

2. **API Gateway**: http://localhost:8000

3. **Test Authentication**:
   ```bash
   # Get access token
   curl -X POST http://localhost:8080/realms/logistics-realm/protocol/openid-connect/token \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin" \
     -d "password=admin123" \
     -d "grant_type=password" \
     -d "client_id=logistics-backend" \
     -d "client_secret=your_keycloak_client_secret"

   # Use token to access protected endpoint
   curl -H "Authorization: Bearer <your-token>" \
     http://localhost:8000/api/user/profile
   ```

## Service Configuration

### Spring Boot Services

Each Spring Boot service requires these dependencies in `pom.xml`:

```xml
<dependency>
    <groupId>org.keycloak</groupId>
    <artifactId>keycloak-spring-boot-starter</artifactId>
    <version>22.0.5</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
```

Add the `SecurityConfig.java` and `KeycloakJwtConverter.java` files to each service.

### Python Services

Python services require these dependencies in `requirements.txt`:

```
python-keycloak==3.7.0
pyjwt[crypto]==2.8.0
cryptography==41.0.7
fastapi==0.104.1
uvicorn==0.24.0
```

Use the `python-keycloak-config.py` for authentication in Python services.

## API Endpoints

### Public Endpoints
- `GET /api/public/health` - Health check (no authentication required)

### User Endpoints
- `GET /api/user/profile` - Get user profile (requires `user` role)
- `POST /api/user/parcels` - Create parcel (requires authentication)

### Admin Endpoints
- `GET /api/admin/users` - Get all users (requires `admin` role)

### Manager Endpoints
- `GET /api/manager/reports` - Get reports (requires `admin` or `manager` role)

### Driver Endpoints
- `GET /api/driver/deliveries` - Get deliveries (requires `admin`, `manager`, or `driver` role)

## Test Users

The setup script creates these test users:

1. **Admin User**
   - Username: `admin`
   - Password: `admin123`
   - Roles: `admin`, `user`

2. **Regular User**
   - Username: `testuser`
   - Password: `test123`
   - Roles: `user`

## Roles and Permissions

- **admin**: Full access to all endpoints
- **manager**: Access to management and user endpoints
- **driver**: Access to driver and user endpoints
- **user**: Basic user access

## Development

### Adding New Endpoints

1. Add the endpoint to your controller
2. Use `@PreAuthorize` annotation for role-based access:
   ```java
   @GetMapping("/api/custom/endpoint")
   @PreAuthorize("hasRole('admin')")
   public ResponseEntity<String> customEndpoint() {
       return ResponseEntity.ok("Custom response");
   }
   ```

### Adding New Roles

1. Add the role in Keycloak Admin Console
2. Assign the role to users
3. Use the role in `@PreAuthorize` annotations

## Troubleshooting

### Common Issues

1. **Keycloak not starting**: Check PostgreSQL is running and accessible
2. **Token verification fails**: Ensure Keycloak URL is correct and accessible from services
3. **Permission denied**: Verify user has required roles assigned

### Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs keycloak
docker-compose logs api-gateway
```

### Reset Keycloak

```bash
# Stop services
docker-compose down

# Remove volumes
docker volume rm logistics_postgres_data

# Restart
docker-compose up -d
```

## Security Considerations

1. Change default passwords in production
2. Use strong client secrets
3. Enable HTTPS for production deployments
4. Regularly update Keycloak and dependencies
5. Implement proper session management
6. Use environment-specific configuration

## Production Deployment

For production deployment:

1. Use external databases (PostgreSQL, MongoDB, Redis)
2. Configure proper HTTPS certificates
3. Set up monitoring and logging
4. Use secrets management
5. Configure backup strategies
6. Set up health checks and monitoring