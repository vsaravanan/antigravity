package com.saravanjs.hello.controller;

import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Sarav on 06 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.controller
 * @class HelloController
 */

@RestController
@RequestMapping("/api")
@Log4j2
public class HelloController {

    public record Message(String details) { }
    public record Db(String url, String username) { }

    @Value("${HOSTNAME}")
    private String podName;

    @GetMapping("/hello")
    public ResponseEntity<Message> sayHello() {
        String msg = "Testing from " + podName;
        log.info(msg);
        Message message = new Message(msg);
        return ResponseEntity.ok(message);
    }

    @GetMapping("/db")
    public ResponseEntity<Db> getDb() {

        String url = System.getenv("DATABASE_URL");
        String user = System.getenv("DATABASE_USER");

        System.out.println(url);
        System.out.println(user);

        Db db = new Db(url, user);
        return ResponseEntity.ok(db);
    }
}