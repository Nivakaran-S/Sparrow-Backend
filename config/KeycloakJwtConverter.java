
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class KeycloakJwtConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        // Extract realm roles
        Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
        Collection<GrantedAuthority> authorities = Collections.emptyList();
        
        if (realmAccess != null && realmAccess.containsKey("roles")) {
            @SuppressWarnings("unchecked")
            List<String> roles = (List<String>) realmAccess.get("roles");
            authorities = roles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()))
                    .collect(Collectors.toList());
        }

        // Extract resource/client roles (optional)
        Map<String, Object> resourceAccess = jwt.getClaimAsMap("resource_access");
        if (resourceAccess != null) {
            resourceAccess.forEach((resource, access) -> {
                @SuppressWarnings("unchecked")
                Map<String, Object> resourceMap = (Map<String, Object>) access;
                if (resourceMap.containsKey("roles")) {
                    @SuppressWarnings("unchecked")
                    List<String> resourceRoles = (List<String>) resourceMap.get("roles");
                    authorities.addAll(resourceRoles.stream()
                            .map(role -> new SimpleGrantedAuthority("ROLE_" + resource.toUpperCase() + "_" + role.toUpperCase()))
                            .collect(Collectors.toList()));
                }
            });
        }

        return authorities;
    }
}