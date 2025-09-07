package com.sparrow.user_service.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.Set;

@Document(collection = "users")
public class User {
  @Id
  private String id;
  private String username;
  private String email;
  private Set<String> roles;

  public User() {}

  public User(String username, String email, Set<String> roles) {
    this.username = username;
    this.email = email;
    this.roles = roles;
  }

  public String getId() { return id; }
  public void setId(String id) { this.id = id; }
  public String getUsername() { return username; }
  public void setUsername(String username) { this.username = username; }
  public String getEmail() { return email; }
  public void setEmail(String email) { this.email = email; }
  public Set<String> getRoles() { return roles; }
  public void setRoles(Set<String> roles) { this.roles = roles; }
}
