package com.sparrow.user_service.controller;

import com.sparrow.user_service.model.User;
import com.sparrow.user_service.service.UserService;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/users")
public class UserController {

  private final UserService userService;

  public UserController(UserService userService) {
    this.userService = userService;
  }

  @PostMapping("/register")
  public ResponseEntity<User> register(@RequestBody RegisterRequest request) {
    User user = new User(request.username(), request.email(), Set.copyOf(request.roles()));
    return ResponseEntity.ok(userService.save(user));
  }

  @GetMapping("/me")
  public ResponseEntity<?> me(@AuthenticationPrincipal Jwt jwt) {
    String username = jwt.getClaimAsString("preferred_username");
    return ResponseEntity.ok(
        userService.findByUsername(username)
            .map(u -> Map.of(
                "id", u.getId(),
                "username", u.getUsername(),
                "email", u.getEmail(),
                "roles", u.getRoles()))
            .orElse(Map.of("username", username, "token-sub", jwt.getSubject()))
    );
  }

  public record RegisterRequest(
      @NotBlank String username,
      @Email String email,
      Set<String> roles
  ) {}
}
