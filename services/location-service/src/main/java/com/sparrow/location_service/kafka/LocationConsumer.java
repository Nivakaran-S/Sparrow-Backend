package com.sparrow.location_service.kafka;

import com.sparrow.location_service.model.DriverLocation;
import com.sparrow.location_service.repository.DriverLocationRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class LocationConsumer {

  private final DriverLocationRepository repository;
  private final ObjectMapper mapper = new ObjectMapper();

  public LocationConsumer(DriverLocationRepository repository) {
    this.repository = repository;
  }

  @KafkaListener(topics = "tracking.location", groupId = "location-service")
  public void onMessage(String message) {
    try {
      JsonNode node = mapper.readTree(message);
      String driverId = node.path("driverId").asText(null);
      double lat = node.path("lat").asDouble();
      double lng = node.path("lng").asDouble();
      long ts = node.path("timestamp").asLong(System.currentTimeMillis());
      if (driverId != null && !driverId.isBlank()) {
        repository.save(new DriverLocation(driverId, lat, lng, ts));
      }
    } catch (Exception ignored) {
      // swallow or log in real system
    }
  }
}
