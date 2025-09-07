#!/bin/bash

echo "Testing Keycloak Authentication and API Gateway..."

# Test users
USERS=("admin:admin123" "manager:manager123" "driver:driver123" "testuser:test123")

for user_cred in "${USERS[@]}"; do
    username=$(echo $user_cred | cut -d: -f1)
    password=$(echo $user_cred | cut -d: -f2)
    
    echo ""
    echo "=========================================="
    echo "Testing user: $username"
    echo "=========================================="
    
    # Get access token
    TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8080/realms/logistics-realm/protocol/openid-connect/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$username" \
        -d "password=$password" \
        -d "grant_type=password" \
        -d "client_id=logistics-backend" \
        -d "client_secret=logistics-secret-2024")
    
    ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token // empty')
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo "❌ Failed to get access token for $username"
        echo "Response: $TOKEN_RESPONSE"
        continue
    fi
    
    echo "✅ Access token obtained for $username"
    
    # Decode JWT to see roles (just for display)
    PAYLOAD=$(echo $ACCESS_TOKEN | cut -d. -f2)
    # Add padding if needed
    PADDING=$((4 - ${#PAYLOAD} % 4))
    if [ $PADDING -ne 4 ]; then
        PAYLOAD="${PAYLOAD}$(printf '=' %.0s $(seq 1 $PADDING))"
    fi
    
    DECODED=$(echo $PAYLOAD | base64 -d 2>/dev/null | jq -r '.realm_access.roles // []' 2>/dev/null)
    echo "🔑 Roles: $DECODED"
    
    # Test API Gateway endpoints
    echo ""
    echo "Testing API endpoints..."
    
    # Test public endpoint (should work without token)
    echo -n "Public endpoint (no auth): "
    PUBLIC_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/actuator/health)
    if [ "$PUBLIC_RESPONSE" == "200" ]; then
        echo "✅ OK"
    else
        echo "❌ Failed ($PUBLIC_RESPONSE)"
    fi
    
    # Test protected user endpoint
    echo -n "User endpoint (/api/user/profile): "
    USER_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        http://localhost:8000/api/user/profile)
    if [ "$USER_RESPONSE" == "200" ]; then
        echo "✅ OK"
    elif [ "$USER_RESPONSE" == "403" ]; then
        echo "🚫 Forbidden (expected for some roles)"
    else
        echo "❌ Failed ($USER_RESPONSE)"
    fi
    
    # Test admin endpoint (only for admin)
    if [ "$username" == "admin" ]; then
        echo -n "Admin endpoint (/api/admin/users): "
        ADMIN_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            http://localhost:8000/api/admin/users)
        if [ "$ADMIN_RESPONSE" == "200" ]; then
            echo "✅ OK"
        else
            echo "❌ Failed ($ADMIN_RESPONSE)"
        fi
    fi
    
    # Test manager endpoint (for admin and manager)
    if [ "$username" == "admin" ] || [ "$username" == "manager" ]; then
        echo -n "Manager endpoint (/api/manager/reports): "
        MANAGER_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            http://localhost:8000/api/manager/reports)
        if [ "$MANAGER_RESPONSE" == "200" ]; then
            echo "✅ OK"
        else
            echo "❌ Failed ($MANAGER_RESPONSE)"
        fi
    fi
    
    # Test driver endpoint (for admin, manager, and driver)
    if [ "$username" == "admin" ] || [ "$username" == "manager" ] || [ "$username" == "driver" ]; then
        echo -n "Driver endpoint (/api/driver/deliveries): "
        DRIVER_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            http://localhost:8000/api/driver/deliveries)
        if [ "$DRIVER_RESPONSE" == "200" ]; then
            echo "✅ OK"
        else
            echo "❌ Failed ($DRIVER_RESPONSE)"
        fi
    fi
    
    # Test service-specific endpoints
    echo -n "Location service: "
    LOCATION_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        http://localhost:8000/api/locations/test-driver/recent)
    if [ "$LOCATION_RESPONSE" == "200" ]; then
        echo "✅ OK"
    elif [ "$LOCATION_RESPONSE" == "403" ]; then
        echo "🚫 Forbidden (expected for regular users)"
    else
        echo "❌ Failed ($LOCATION_RESPONSE)"
    fi
    
    echo -n "Notification service: "
    NOTIFICATION_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        http://localhost:8000/api/notifications)
    if [ "$NOTIFICATION_RESPONSE" == "200" ]; then
        echo "✅ OK"
    elif [ "$NOTIFICATION_RESPONSE" == "403" ]; then
        echo "🚫 Forbidden"
    else
        echo "❌ Failed ($NOTIFICATION_RESPONSE)"
    fi
done

echo ""
echo "=========================================="
echo "Authentication test completed!"
echo "=========================================="
echo ""
echo "To get a token manually:"
echo "curl -X POST http://localhost:8080/realms/logistics-realm/protocol/openid-connect/token \\"
echo "  -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "  -d 'username=admin' \\"
echo "  -d 'password=admin123' \\"
echo "  -d 'grant_type=password' \\"
echo "  -d 'client_id=logistics-backend' \\"
echo "  -d 'client_secret=logistics-secret-2024'"