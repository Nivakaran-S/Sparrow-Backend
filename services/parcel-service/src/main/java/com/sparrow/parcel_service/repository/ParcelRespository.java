package com.sparrow.parcel_service.repository;

import com.sparrow.parcel_service.model.Parcel;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ParcelRepository extends MongoRepository<Parcel, String> {
}
