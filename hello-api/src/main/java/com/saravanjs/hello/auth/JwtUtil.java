package com.saravanjs.hello.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.auth
 * @class JwtUtil
 */
public class JwtUtil {

    private static final String SECRET = "my-secret";

    public static String createToken(String username) {

        return Jwts.builder()
                .subject(username)
                .signWith(Keys.hmacShaKeyFor(SECRET.getBytes()))
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