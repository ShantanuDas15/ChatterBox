package com.chatterbox.service;

import com.chatterbox.model.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {

    private final SecretKey secretKey;
    private final long expiration = 864_000_000; // 10 days

    public JwtService(@Value("${jwt.secret}") String secret) {
        // Create a secure key from the secret string
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(Authentication authentication) {
        OAuth2User userPrincipal = (OAuth2User) authentication.getPrincipal();
        Map<String, Object> attributes = userPrincipal.getAttributes();

        String userId = userPrincipal.getName(); // This is the user's Google ID
        String photoUrl = (String) attributes.get("picture");

        return Jwts.builder()
                .setSubject(userId)
                .claim("name", attributes.get("name"))
                .claim("email", attributes.get("email"))
                .claim("picture", photoUrl)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(secretKey, SignatureAlgorithm.HS256)
                .compact();
    }

    // --- ADD THESE NEW METHODS ---

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String extractUserId(String token) {
        return extractAllClaims(token).getSubject(); // Returns the Google ID
    }

    public String extractUsername(String token) {
        return (String) extractAllClaims(token).get("name");
    }

    public boolean isTokenValid(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(secretKey)
                    .build()
                    .parseClaimsJws(token);
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        return extractAllClaims(token).getExpiration().before(new Date());
    }

    public String generateTokenForUser(User user) {
        return Jwts.builder()
                .setSubject(user.getGoogleId())
                .claim("name", user.getUsername())
                .claim("email", user.getEmail())
                .claim("picture", user.getPhotoUrl())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(secretKey, SignatureAlgorithm.HS256)
                .compact();
    }
}
