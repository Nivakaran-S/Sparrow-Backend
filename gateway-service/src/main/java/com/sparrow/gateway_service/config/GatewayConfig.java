package com.sparrow.gateway_service.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayConfig {

    @Bean("userKeyResolver")
    public KeyResolver userKeyResolver() {
        return exchange -> exchange.getRequest()
                .getHeaders()
                .getFirst("Authorization") != null 
                    ? Mono.just(exchange.getRequest().getHeaders().getFirst("Authorization"))
                    : Mono.just(exchange.getRequest().getRemoteAddress().toString());
    }
}