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

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin access token. Please check Keycloak status and credentials."
    exit 1
fi

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
        "editUsernameAllowed": false,
        "bruteForceProtected": true,
        "permanentLockout": false,
        "maxFailureWaitSeconds": 900,
        "minimumQuickLoginWaitSeconds": 60,
        "waitIncrementSeconds": 60,
        "quickLoginCheckMilliSeconds": 1000,
        "maxDeltaTimeSeconds": 43200,
        "failureFactor": 30
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

echo "Roles created successfully."

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
        "fullScopeAllowed": true,
        "redirectUris": ["http://localhost:8000/*", "http://localhost:3000/*"],
        "webOrigins": ["http://localhost:8000", "http://localhost:3000"],
        "defaultClientScopes": [
            "web-origins",
            "role_list", 
            "profile",
            "roles",
            "email"
        ],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt"
        ]
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
        "fullScopeAllowed": true,
        "redirectUris": ["http://localhost:3000/*"],
        "webOrigins": ["http://localhost:3000"],
        "defaultClientScopes": [
            "web-origins",
            "role_list",
            "profile", 
            "roles",
            "email"
        ],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access"
        ]
    }'

echo "Clients created successfully."

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

# Manager user  
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
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
    }'

# Driver user
curl -s -X POST http://localhost:8080/admin/realms/logistics-realm/users \
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

echo "Users created successfully."

# Wait a moment for users to be created
sleep 3

# Get user IDs
ADMIN_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=admin" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

MANAGER_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=manager" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

DRIVER_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=driver" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

TEST_USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/logistics-realm/users?username=testuser" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

# Assign roles to users
echo "Assigning roles to users..."

# Admin user gets admin and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$ADMIN_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "admin"}, {"name": "user"}]'

# Manager gets manager and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$MANAGER_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "manager"}, {"name": "user"}]'

# Driver gets driver and user roles
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$DRIVER_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "driver"}, {"name": "user"}]'

# Test user gets user role
curl -s -X POST "http://localhost:8080/admin/realms/logistics-realm/users/$TEST_USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '[{"name": "user"}]'

echo "Role assignments completed successfully."

echo ""
echo "============================================"
echo "Keycloak setup completed successfully!"
echo "============================================"
echo ""
echo "Realm: logistics-realm"
echo "Client ID (Backend): logistics-backend"
echo "Client Secret: logistics-secret-2024"
echo "Client ID (Frontend): logistics-frontend (public)"
echo ""
echo "Access Keycloak Admin Console at: http://localhost:8080"
echo "Keycloak Admin: admin / admin"
echo ""
echo "Test users created:"
echo "┌──────────┬──────────┬─────────────┬──────────────────────┐"
echo "│ Username │ Password │ Roles       │ Email                │"
echo "├──────────┼──────────┼─────────────┼──────────────────────┤"
echo "│ admin    │ admin123 │ admin, user │ admin@logistics.com  │"
echo "│ manager  │ manager123 │ manager, user │ manager@logistics.com │"
echo "│ driver   │ driver123 │ driver, user │ driver@logistics.com │"
echo "│ testuser │ test123  │ user        │ test@logistics.com   │"
echo "└──────────┴──────────┴─────────────┴──────────────────────┘"
echo ""
echo "Test authentication:"
echo "curl -X POST http://localhost:8080/realms/logistics-realm/protocol/openid-connect/token \\"
echo "  -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "  -d 'username=admin' \\"
echo "  -d 'password=admin123' \\"
echo "  -d 'grant_type=password' \\"
echo "  -d 'client_id=logistics-backend' \\"
echo "  -d 'client_secret=logistics-secret-2024'"