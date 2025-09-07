package com.sparrow.location_service.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "driver_locations")
public class DriverLocation {
  @Id
  private String id;

  @Indexed
  private String driverId;

  private double lat;
  private double lng;
  private long timestamp;

  public DriverLocation() {}

  public DriverLocation(String driverId, double lat, double lng, long timestamp) {
    this.driverId = driverId;
    this.lat = lat;
    this.lng = lng;
    this.timestamp = timestamp;
  }

  public String getId() { return id; }
  public void setId(String id) { this.id = id; }
  public String getDriverId() { return driverId; }
  public void setDriverId(String driverId) { this.driverId = driverId; }
  public double getLat() { return lat; }
  public void setLat(double lat) { this.lat = lat; }
  public double getLng() { return lng; }
  public void setLng(double lng) { this.lng = lng; }
  public long getTimestamp() { return timestamp; }
  public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}
