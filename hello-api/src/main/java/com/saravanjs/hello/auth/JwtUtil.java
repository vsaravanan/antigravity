package com.saravanjs.hello.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.auth
 * @class JwtUtil
 */
@Component
public class JwtUtil {

    private static final String SECRET = "my-secret";

    private final SecretKey key;

    public JwtUtil() {
        this.key = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));
    }

    public String createToken(String username) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(username)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(1, ChronoUnit.HOURS)))
                .signWith(key)
                .compact();
    }

    public static String getUser(String authorizationHeader) {

        // Remove "Bearer "
        String token = authorizationHeader.replace("Bearer ", "");

        Claims claims = Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(SECRET.getBytes()))
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }
}