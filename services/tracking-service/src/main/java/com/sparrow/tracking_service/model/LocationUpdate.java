package com.sparrow.tracking_service.model;

public class LocationUpdate {
  private String driverId;
  private double lat;
  private double lng;
  private long timestamp;

  public LocationUpdate() {}

  public LocationUpdate(String driverId, double lat, double lng, long timestamp) {
    this.driverId = driverId;
    this.lat = lat;
    this.lng = lng;
    this.timestamp = timestamp;
  }

  public String getDriverId() { return driverId; }
  public void setDriverId(String driverId) { this.driverId = driverId; }
  public double getLat() { return lat; }
  public void setLat(double lat) { this.lat = lat; }
  public double getLng() { return lng; }
  public void setLng(double lng) { this.lng = lng; }
  public long getTimestamp() { return timestamp; }
  public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}
