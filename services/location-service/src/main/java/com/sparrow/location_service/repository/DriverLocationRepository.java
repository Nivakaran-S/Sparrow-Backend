package com.sparrow.location_service.repository;

import com.sparrow.location_service.model.DriverLocation;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface DriverLocationRepository extends MongoRepository<DriverLocation, String> {
  List<DriverLocation> findByDriverIdOrderByTimestampDesc(String driverId, Pageable pageable);
}
