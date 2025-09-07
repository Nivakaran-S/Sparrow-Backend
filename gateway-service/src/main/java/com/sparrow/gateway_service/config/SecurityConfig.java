package com.sparrow.gateway_service.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableReactiveMethodSecurity;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebFluxSecurity
@EnableReactiveMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchanges -> exchanges
                        // Public endpoints - no authentication required
                        .pathMatchers("/actuator/health", "/actuator/info").permitAll()
                        .pathMatchers("/actuator/**").permitAll()
                        .pathMatchers("/api/public/**").permitAll()
                        .pathMatchers("/fallback").permitAll()
                        
                        // Admin endpoints - requires admin role
                        .pathMatchers("/api/admin/**").hasRole("ADMIN")
                        
                        // Manager endpoints - requires admin or manager role
                        .pathMatchers("/api/manager/**").hasAnyRole("ADMIN", "MANAGER")
                        
                        // Driver endpoints - requires admin, manager, or driver role
                        .pathMatchers("/api/driver/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER")
                        
                        // User endpoints - requires any authenticated role
                        .pathMatchers("/api/user/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        
                        // Service-specific endpoints
                        .pathMatchers("/api/parcel/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        .pathMatchers("/api/tracking/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        .pathMatchers("/api/notification/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        .pathMatchers("/api/location/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER")
                        .pathMatchers("/api/chatbot/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        .pathMatchers("/api/eta/**").hasAnyRole("ADMIN", "MANAGER", "DRIVER", "USER")
                        
                        // All other requests need authentication
                        .anyExchange().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwtAuthenticationConverter(new ReactiveJwtAuthenticationConverterAdapter(jwtAuthenticationConverter()))
                        )
                )
                .build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(new KeycloakJwtConverter());
        return converter;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(Arrays.asList(
                HttpMethod.GET.name(),
                HttpMethod.POST.name(),
                HttpMethod.PUT.name(),
                HttpMethod.DELETE.name(),
                HttpMethod.OPTIONS.name()
        ));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}