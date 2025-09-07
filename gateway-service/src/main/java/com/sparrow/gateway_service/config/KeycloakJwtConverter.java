package com.sparrow.gateway_service.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class KeycloakJwtConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        Collection<GrantedAuthority> authorities = new ArrayList<>();
        
        // Extract realm roles
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        if (realmAccess != null && realmAccess.containsKey("roles")) {
            @SuppressWarnings("unchecked")
            List<String> roles = (List<String>) realmAccess.get("roles");
            if (roles != null) {
                authorities.addAll(roles.stream()
                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()))
                        .collect(Collectors.toList()));
            }
        }

        // Extract resource/client roles (optional)
        Map<String, Object> resourceAccess = jwt.getClaimAsMap("resource_access");
        if (resourceAccess != null) {
            resourceAccess.forEach((resource, access) -> {
                if (access instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> resourceMap = (Map<String, Object>) access;
                    if (resourceMap != null && resourceMap.containsKey("roles")) {
                        @SuppressWarnings("unchecked")
                        List<String> resourceRoles = (List<String>) resourceMap.get("roles");
                        if (resourceRoles != null) {
                            authorities.addAll(resourceRoles.stream()
                                    .map(role -> new SimpleGrantedAuthority("ROLE_" + resource.toUpperCase() + "_" + role.toUpperCase()))
                                    .collect(Collectors.toList()));
                        }
                    }
                }
            });
        }

        return authorities.isEmpty() ? Collections.emptyList() : authorities;
    }
}