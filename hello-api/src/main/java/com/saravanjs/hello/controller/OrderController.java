package com.saravanjs.hello.controller;

import com.saravanjs.hello.model.Order;
import com.saravanjs.hello.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping
    @PreAuthorize("hasRole('MAKER')")
    public ResponseEntity<Order> createOrder(@RequestBody Order order) {
        Order created = orderService.createOrder(order.getProductName(), order.getQuantity());
        return ResponseEntity.ok(created);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MAKER', 'CHECKER')")
    public ResponseEntity<List<Order>> getAllOrders() {
        return ResponseEntity.ok(orderService.getAllOrders());
    }

    @GetMapping("/maker")
    @PreAuthorize("hasRole('MAKER')")
    public ResponseEntity<List<Order>> getOrdersByMaker() {
        return ResponseEntity.ok(orderService.getOrdersByMaker(null));
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('CHECKER')")
    public ResponseEntity<Order> approveOrder(@PathVariable Long id) {
        Order approved = orderService.approveOrder(id);
        if (approved != null) {
            return ResponseEntity.ok(approved);
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('MAKER')")
    public ResponseEntity<Void> deleteOrder(@PathVariable Long id) {
        orderService.deleteOrder(id);
        return ResponseEntity.noContent().build();
    }
}
