package com.sparrow.notification_service.controller;

import com.sparrow.notification_service.kafka.NotificationConsumer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

  private final NotificationConsumer consumer;

  public NotificationController(NotificationConsumer consumer) {
    this.consumer = consumer;
  }

  @GetMapping
  public ResponseEntity<List<String>> list() {
    return ResponseEntity.ok(consumer.recent());
  }
}
