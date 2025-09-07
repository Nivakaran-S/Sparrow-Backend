package com.sparrow.parcel_service.controller;

import com.sparrow.parcel_service.model.Parcel;
import com.sparrow.parcel_service.repository.ParcelRepository;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/parcels")
public class ParcelController {

  private final ParcelRepository repo;

  public ParcelController(ParcelRepository repo) {
    this.repo = repo;
  }

  @PostMapping
  public ResponseEntity<Parcel> create(@RequestBody CreateParcelRequest req) {
    Parcel p = new Parcel(req.customerId(), req.originAddress(), req.destinationAddress(), req.destLat(), req.destLng(), "CREATED");
    return ResponseEntity.ok(repo.save(p));
  }

  @GetMapping
  public List<Parcel> list() {
    return repo.findAll();
  }

  @GetMapping("/{id}")
  public ResponseEntity<Parcel> get(@PathVariable String id) {
    return repo.findById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
  }

  public record CreateParcelRequest(
      @NotBlank String customerId,
      @NotBlank String originAddress,
      @NotBlank String destinationAddress,
      @NotNull Double destLat,
      @NotNull Double destLng
  ) {}
}
