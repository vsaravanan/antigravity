package com.saravanjs.hello.controller;

import com.saravanjs.hello.auth.JwtUtil;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.controller
 * @class LoginController
 */
@RestController
@RequestMapping("/api")
public class LoginController {

    @PostMapping("/login")
    public String login() {

        return JwtUtil.createToken("userA");

    }

}