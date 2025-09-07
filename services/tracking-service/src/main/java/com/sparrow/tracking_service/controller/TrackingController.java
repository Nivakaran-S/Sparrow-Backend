package com.sparrow.tracking_service.controller;

import com.sparrow.tracking_service.model.LocationUpdate;
import com.sparrow.tracking_service.service.EtaClient;
import jakarta.validation.constraints.NotNull;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.Instant;

@RestController
@RequestMapping("/api/tracking")
public class TrackingController {

  private final KafkaTemplate<String, String> kafkaTemplate;
  private final EtaClient etaClient;

  public TrackingController(KafkaTemplate<String, String> kafkaTemplate, EtaClient etaClient) {
    this.kafkaTemplate = kafkaTemplate;
    this.etaClient = etaClient;
  }

  @PostMapping("/update")
  public ResponseEntity<?> update(@RequestBody LocationUpdate update) {
    if (update.getTimestamp() == 0) {
      update.setTimestamp(Instant.now().toEpochMilli());
    }
    // Serialize manually to keep minimal deps
    String payload = String.format("{\"driverId\":\"%s\",\"lat\":%f,\"lng\":%f,\"timestamp\":%d}",
        update.getDriverId(), update.getLat(), update.getLng(), update.getTimestamp());
    kafkaTemplate.send(new ProducerRecord<>("tracking.location", update.getDriverId(), payload));
    return ResponseEntity.accepted().build();
  }

  @GetMapping(value = "/eta", produces = MediaType.APPLICATION_JSON_VALUE)
  public Mono<ResponseEntity<String>> eta(
      @RequestParam("originLat") @NotNull Double originLat,
      @RequestParam("originLng") @NotNull Double originLng,
      @RequestParam("destLat") @NotNull Double destLat,
      @RequestParam("destLng") @NotNull Double destLng
  ) {
    return etaClient.getEta(originLat, originLng, destLat, destLng)
        .map(body -> ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(body));
  }
}
