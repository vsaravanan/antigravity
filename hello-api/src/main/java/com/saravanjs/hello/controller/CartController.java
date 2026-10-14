package com.saravanjs.hello.controller;

import com.saravanjs.hello.auth.JwtUtil;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.controller.cart
 * @class CartController
 */
@RestController
@RequestMapping("/api")
public class CartController {
    @GetMapping("/cart")
    public String cart(
            @RequestHeader("Authorization") String token) {

        String user = JwtUtil.getUser(token);

        return "Hello " + user;
    }
}
