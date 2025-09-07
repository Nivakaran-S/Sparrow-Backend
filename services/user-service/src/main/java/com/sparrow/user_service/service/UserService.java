package com.sparrow.user_service.service;

import com.sparrow.user_service.model.User;
import com.sparrow.user_service.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {
  private final UserRepository repo;

  public UserService(UserRepository repo) {
    this.repo = repo;
  }

  public User save(User user) {
    return repo.save(user);
  }

  public Optional<User> findByUsername(String username) {
    return repo.findByUsername(username);
  }
}
