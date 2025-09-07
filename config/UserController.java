
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class UserController {

    @GetMapping("/public/health")
    public ResponseEntity<Map<String, String>> publicHealth() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "Public endpoint accessible");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/profile")
    @PreAuthorize("hasRole('user')")
    public ResponseEntity<Map<String, Object>> getUserProfile(@AuthenticationPrincipal Jwt jwt) {
        Map<String, Object> profile = new HashMap<>();
        profile.put("username", jwt.getClaimAsString("preferred_username"));
        profile.put("email", jwt.getClaimAsString("email"));
        profile.put("firstName", jwt.getClaimAsString("given_name"));
        profile.put("lastName", jwt.getClaimAsString("family_name"));
        profile.put("roles", jwt.getClaimAsMap("realm_access").get("roles"));
        
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/admin/users")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<Map<String, String>> getUsers(@AuthenticationPrincipal Jwt jwt) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Admin access granted");
        response.put("user", jwt.getClaimAsString("preferred_username"));
        return ResponseEntity.ok(response);
    }

    @GetMapping("/manager/reports")
    @PreAuthorize("hasAnyRole('admin', 'manager')")
    public ResponseEntity<Map<String, String>> getReports(@AuthenticationPrincipal Jwt jwt) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Manager/Admin access granted");
        response.put("user", jwt.getClaimAsString("preferred_username"));
        return ResponseEntity.ok(response);
    }

    @GetMapping("/driver/deliveries")
    @PreAuthorize("hasAnyRole('admin', 'manager', 'driver')")
    public ResponseEntity<Map<String, String>> getDeliveries(@AuthenticationPrincipal Jwt jwt) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Driver access granted");
        response.put("user", jwt.getClaimAsString("preferred_username"));
        return ResponseEntity.ok(response);
    }

    @PostMapping("/user/parcels")
    @PreAuthorize("hasAnyRole('admin', 'manager', 'driver', 'user')")
    public ResponseEntity<Map<String, String>> createParcel(@AuthenticationPrincipal Jwt jwt, @RequestBody Map<String, Object> parcel) {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Parcel created successfully");
        response.put("user", jwt.getClaimAsString("preferred_username"));
        response.put("parcelId", "PKG-" + System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }
}