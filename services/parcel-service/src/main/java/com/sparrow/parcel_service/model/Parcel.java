package com.sparrow.parcel_service.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "parcels")
public class Parcel {
  @Id
  private String id;
  private String customerId;
  private String originAddress;
  private String destinationAddress;
  private double destLat;
  private double destLng;
  private String status;

  public Parcel() {}

  public Parcel(String customerId, String originAddress, String destinationAddress, double destLat, double destLng, String status) {
    this.customerId = customerId;
    this.originAddress = originAddress;
    this.destinationAddress = destinationAddress;
    this.destLat = destLat;
    this.destLng = destLng;
    this.status = status;
  }

  public String getId() { return id; }
  public void setId(String id) { this.id = id; }
  public String getCustomerId() { return customerId; }
  public void setCustomerId(String customerId) { this.customerId = customerId; }
  public String getOriginAddress() { return originAddress; }
  public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }
  public String getDestinationAddress() { return destinationAddress; }
  public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }
  public double getDestLat() { return destLat; }
  public void setDestLat(double destLat) { this.destLat = destLat; }
  public double getDestLng() { return destLng; }
  public void setDestLng(double destLng) { this.destLng = destLng; }
  public String getStatus() { return status; }
  public void setStatus(String status) { this.status = status; }
}
