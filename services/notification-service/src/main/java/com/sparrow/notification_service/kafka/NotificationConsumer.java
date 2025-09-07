package com.sparrow.notification_service.kafka;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.List;

@Service
public class NotificationConsumer {

  private static final int MAX_BUFFER = 100;
  private final Deque<String> messages = new ArrayDeque<>();

  @KafkaListener(topics = "tracking.location", groupId = "notification-service")
  public void onMessage(String message) {
    String entry = "[" + Instant.now() + "] " + message;
    synchronized (messages) {
      messages.addFirst(entry);
      while (messages.size() > MAX_BUFFER) {
        messages.removeLast();
      }
    }
  }

  public List<String> recent() {
    synchronized (messages) {
      return List.copyOf(messages);
    }
  }
}
