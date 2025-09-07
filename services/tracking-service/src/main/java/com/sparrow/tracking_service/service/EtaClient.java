package com.sparrow.tracking_service.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Component
public class EtaClient {

  private final WebClient webClient;

  public EtaClient(@Value("${eta.base-url:http://eta-service:9000}") String baseUrl) {
    this.webClient = WebClient.builder().baseUrl(baseUrl).build();
  }

  public Mono<String> getEta(double originLat, double originLng, double destLat, double destLng) {
    return webClient.get()
        .uri(uriBuilder -> uriBuilder
            .path("/eta")
            .queryParam("origin_lat", originLat)
            .queryParam("origin_lng", originLng)
            .queryParam("dest_lat", destLat)
            .queryParam("dest_lng", destLng)
            .build())
        .retrieve()
        .bodyToMono(String.class);
  }
}
