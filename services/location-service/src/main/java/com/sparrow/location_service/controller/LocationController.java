package com.sparrow.location_service.controller;

import com.sparrow.location_service.model.DriverLocation;
import com.sparrow.location_service.repository.DriverLocationRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/locations")
public class LocationController {

  private final DriverLocationRepository repository;

  public LocationController(DriverLocationRepository repository) {
    this.repository = repository;
  }

  @GetMapping("/{driverId}/recent")
  public ResponseEntity<List<DriverLocation>> recent(@PathVariable String driverId,
                                                     @RequestParam(defaultValue = "20") int limit) {
    int pageSize = Math.min(Math.max(limit, 1), 100);
    List<DriverLocation> items = repository.findByDriverIdOrderByTimestampDesc(driverId, PageRequest.of(0, pageSize));
    return ResponseEntity.ok(items);
  }
}
