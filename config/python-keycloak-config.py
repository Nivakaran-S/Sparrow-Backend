# Python Keycloak Integration for FastAPI services
# Add these dependencies to requirements.txt:
# python-keycloak==3.7.0
# pyjwt[crypto]==2.8.0
# cryptography==41.0.7

import os
from functools import wraps
import jwt
from jwt import PyJWTError
import requests
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

class KeycloakConfig:
    def __init__(self):
        self.server_url = os.getenv('KEYCLOAK_SERVER_URL', 'http://keycloak:8080')
        self.realm = os.getenv('KEYCLOAK_REALM', 'logistics-realm')
        self.client_id = os.getenv('KEYCLOAK_CLIENT_ID', 'logistics-backend')
        self.client_secret = os.getenv('KEYCLOAK_CLIENT_SECRET', 'your_keycloak_client_secret')
        
        # Keycloak URLs
        self.auth_url = f"{self.server_url}/realms/{self.realm}/protocol/openid-connect/auth"
        self.token_url = f"{self.server_url}/realms/{self.realm}/protocol/openid-connect/token"
        self.userinfo_url = f"{self.server_url}/realms/{self.realm}/protocol/openid-connect/userinfo"
        self.jwks_url = f"{self.server_url}/realms/{self.realm}/protocol/openid-connect/certs"
        self.logout_url = f"{self.server_url}/realms/{self.realm}/protocol/openid-connect/logout"

class KeycloakAuth:
    def __init__(self):
        self.config = KeycloakConfig()
        self.security = HTTPBearer()
        self._public_keys = None
    
    def get_public_keys(self):
        """Fetch public keys from Keycloak for token verification"""
        if self._public_keys is None:
            try:
                response = requests.get(self.config.jwks_url)
                response.raise_for_status()
                self._public_keys = response.json()
            except requests.RequestException as e:
                raise HTTPException(status_code=500, detail=f"Failed to fetch public keys: {str(e)}")
        return self._public_keys
    
    def verify_token(self, token: str) -> dict:
        """Verify JWT token and return decoded payload"""
        try:
            # Get public keys from Keycloak
            jwks = self.get_public_keys()
            
            # Decode header to get key ID
            header = jwt.get_unverified_header(token)
            kid = header.get('kid')
            
            # Find the correct key
            key = None
            for jwk in jwks['keys']:
                if jwk['kid'] == kid:
                    key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
                    break
            
            if not key:
                raise HTTPException(status_code=401, detail="Public key not found")
            
            # Verify and decode token
            payload = jwt.decode(
                token,
                key,
                algorithms=['RS256'],
                audience=self.config.client_id,
                issuer=f"{self.config.server_url}/realms/{self.config.realm}"
            )
            
            return payload
            
        except PyJWTError as e:
            raise HTTPException(status_code=401, detail=f"Token verification failed: {str(e)}")
    
    def get_current_user(self, credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer())):
        """FastAPI dependency to get current authenticated user"""
        token = credentials.credentials
        payload = self.verify_token(token)
        return payload
    
    def require_roles(self, required_roles: list):
        """Decorator to require specific roles"""
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                # Get user from kwargs (assumes get_current_user dependency is used)
                user = None
                for key, value in kwargs.items():
                    if isinstance(value, dict) and 'realm_access' in value:
                        user = value
                        break
                
                if not user:
                    raise HTTPException(status_code=401, detail="Authentication required")
                
                user_roles = user.get('realm_access', {}).get('roles', [])
                
                if not any(role in user_roles for role in required_roles):
                    raise HTTPException(status_code=403, detail="Insufficient permissions")
                
                return func(*args, **kwargs)
            return wrapper
        return decorator

# Initialize Keycloak auth instance
keycloak_auth = KeycloakAuth()

# Example usage in FastAPI routes
"""
from fastapi import FastAPI, Depends

app = FastAPI()

@app.get("/api/public/health")
async def public_health():
    return {"status": "UP", "message": "Public endpoint accessible"}

@app.get("/api/user/profile")
async def get_user_profile(current_user: dict = Depends(keycloak_auth.get_current_user)):
    return {
        "username": current_user.get("preferred_username"),
        "email": current_user.get("email"),
        "roles": current_user.get("realm_access", {}).get("roles", [])
    }

@app.get("/api/admin/users")
@keycloak_auth.require_roles(["admin"])
async def get_users(current_user: dict = Depends(keycloak_auth.get_current_user)):
    return {"message": "Admin access granted", "user": current_user.get("preferred_username")}
"""