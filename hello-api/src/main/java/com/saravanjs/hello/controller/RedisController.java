package com.saravanjs.hello.controller;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.controller
 * @class RedisController
 */

import com.saravanjs.hello.model.ProductRecord;
import com.saravanjs.hello.service.RedisService;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.Set;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/redis")
@Log4j2
public class RedisController {

    private final RedisService redisService;


    @RequestMapping(value = "/init", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<String> init() {

        redisService.init();
        log.info("init");

        return ResponseEntity.ok("Inserted Product1...Product10");
    }

    @RequestMapping(value = "/buy/{user}", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<ProductRecord> buy(
            @PathVariable String user) {
        ProductRecord productRecord = redisService.buy(user);
        log.info(user + " buy " + productRecord );
        return ResponseEntity.ok(productRecord);
    }

    @RequestMapping(value = "/stock", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<Set<ProductRecord>> stock() {

        Set<ProductRecord> stockList = redisService.getStock();

        log.info("Current stock " + stockList);

        return ResponseEntity.ok(stockList);
    }


    @RequestMapping(value = "/cart/{user}", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<Set<ProductRecord>> cart(
            @PathVariable String user) {

        Set<ProductRecord> stockList = redisService.getCart(user);

        log.info("user cart " + user + " : " + stockList);

        return ResponseEntity.ok(stockList);

    }
}