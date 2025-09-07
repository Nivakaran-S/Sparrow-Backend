#!/bin/bash

echo "Setting up Keycloak realm and clients..."

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to start..."
until curl -f http://localhost:8080/health/ready; do
    echo "Keycloak is not ready yet. Waiting..."
    sleep 5
done

echo "Keycloak is ready!"

# Get admin access token
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

echo "Admin token obtained: ${ADMIN_TOKEN:0:20}..."

# Create realm
echo "Creating logistics-realm..."
curl -s -X POST http://localhost:8080/admin/realms \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "id": "logistics-realm",
        "realm": "logistics-realm",
        "displayName": "Logistics Realm",
        "enabled": true,
        "registrationAllowed": true,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,
        "editUsernameAllowed": false
    }'

# Create backend client
echo "Creating backend client..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/clients \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "logistics-backend",
        "name": "Logistics Backend Service",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "logistics-secret-2024",
        "bearerOnly": false,
        "consentRequired": false,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": true,
        "publicClient": false,
        "protocol": "openid-connect",
        "redirectUris": ["http://localhost:8000/*", "http://localhost:3000/*"],
        "webOrigins": ["http://localhost:8000", "http://localhost:3000"]
    }'

# Create frontend client
echo "Creating frontend client..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/clients \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "logistics-frontend",
        "name": "Logistics Frontend Application",
        "enabled": true,
        "bearerOnly": false,
        "consentRequired": false,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": false,
        "publicClient": true,
        "protocol": "openid-connect",
        "redirectUris": ["http://localhost:3000/*"],
        "webOrigins": ["http://localhost:3000"]
    }'

# Create realm roles
echo "Creating realm roles..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "user", "description": "Standard user role"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "driver", "description": "Driver role for delivery personnel"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "manager", "description": "Manager role for supervisors"}'

# Create test users
echo "Creating test users..."

# Admin user
ADMIN_USER_ID=$(curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "admin",
        "email": "admin@logistics.com",
        "firstName": "Admin",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "admin123",
            "temporary": false
        }]
    }' | jq -r '.id // empty')

# Regular user
TEST_USER_ID=$(curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser",
        "email": "test@logistics.com",
        "firstName": "Test",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "test123",
            "temporary": false
        }]
    }' | jq -r '.id // empty')

# Driver user
DRIVER_USER_ID=$(curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "driver",
        "email": "driver@logistics.com",
        "firstName": "John",
        "lastName": "Driver",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "driver123",
            "temporary": false
        }]
    }' | jq -r '.id // empty')

# Manager user  
MANAGER_USER_ID=$(curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "manager",
        "email": "manager@logistics.com",
        "firstName": "Jane",
        "lastName": "Manager",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "manager123",
            "temporary": false
        }]
    }' | jq -r '.id // empty')

sleep 2

# Get user IDs if creation response didn't include them
if [ -z "$ADMIN_USER_ID" ]; then
    ADMIN_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=admin" \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
fi

if [ -z "$TEST_USER_ID" ]; then
    TEST_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=testuser" \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
fi

if [ -z "$DRIVER_USER_ID" ]; then
    DRIVER_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=driver" \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
fi

if [ -z "$MANAGER_USER_ID" ]; then
    MANAGER_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=manager" \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
fi

# Assign roles to users
echo "Assigning roles to users..."

# Admin user gets admin and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$ADMIN_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "admin"}, {"name": "user"}]'

# Test user gets user role
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$TEST_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "user"}]'

# Driver gets driver and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$DRIVER_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "driver"}, {"name": "user"}]'

# Manager gets manager and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$MANAGER_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "manager"}, {"name": "user"}]'

echo "Keycloak setup completed!"
echo "Access Keycloak Admin Console at: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Test users created:"
echo "Admin    - username: admin,    password: admin123"
echo "Manager  - username: manager,  password: manager123"
echo "Driver   - username: driver,   password: driver123"
echo "User     - username: testuser, password: test123"name": "admin", "description": "Administrator role with full access"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"#!/bin/bash

echo "Setting up Keycloak realm and clients..."

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to start..."
until curl -f http://localhost:8080/health/ready; do
    echo "Keycloak is not ready yet. Waiting..."
    sleep 5
done

echo "Keycloak is ready!"

# Get admin access token
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

echo "Admin token obtained: ${ADMIN_TOKEN:0:20}..."

# Create realm
echo "Creating logistics-realm..."
curl -s -X POST http://localhost:8080/admin/realms \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "id": "logistics-realm",
        "realm": "logistics-realm",
        "displayName": "Logistics Realm",
        "enabled": true,
        "registrationAllowed": true,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,
        "editUsernameAllowed": false
    }'

# Create backend client
echo "Creating backend client..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/clients \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "logistics-backend",
        "name": "Logistics Backend Service",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "your_keycloak_client_secret",
        "bearerOnly": false,
        "consentRequired": false,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": true,
        "publicClient": false,
        "protocol": "openid-connect",
        "redirectUris": ["http://localhost:8000/*", "http://localhost:3000/*"],
        "webOrigins": ["http://localhost:8000", "http://localhost:3000"]
    }'

# Create frontend client
echo "Creating frontend client..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/clients \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "logistics-frontend",
        "name": "Logistics Frontend Application",
        "enabled": true,
        "bearerOnly": false,
        "consentRequired": false,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": false,
        "publicClient": true,
        "protocol": "openid-connect",
        "redirectUris": ["http://localhost:3000/*"],
        "webOrigins": ["http://localhost:3000"]
    }'

# Create realm roles
echo "Creating realm roles..."
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "admin", "description": "Administrator role with full access"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "user", "description": "Standard user role"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "driver", "description": "Driver role for delivery personnel"}'

curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "manager", "description": "Manager role for supervisors"}'

# Create test users
echo "Creating test users..."

# Admin user
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "admin",
        "email": "admin@logistics.com",
        "firstName": "Admin",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "admin123",
            "temporary": false
        }]
    }'

# Regular user
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser",
        "email": "test@logistics.com",
        "firstName": "Test",
        "lastName": "User",
        "enabled": true,
        "emailVerified": true,
        "credentials": [{
            "type": "password",
            "value": "test123",
            "temporary": false
        }]
    }'

echo "Keycloak setup completed!"
echo "Access Keycloak Admin Console at: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Test users created:"
echo "Admin - username: admin, password: admin123"
echo "User - username: testuser, password: test123"