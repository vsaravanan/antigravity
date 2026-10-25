package com.saravanjs.hello.service;

import com.saravanjs.hello.model.Order;
import com.saravanjs.hello.model.OrderStatus;
import com.saravanjs.hello.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    public Order createOrder(String productName, int quantity) {
        Order order = new Order();
        order.setProductName(productName);
        order.setQuantity(quantity);
        order.setStatus(OrderStatus.DRAFT);
        order.setCreatedBy(getCurrentUsername());
        return orderRepository.save(order);
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public List<Order> getOrdersByMaker(String username) {
        if  (username == null) {
            username = getCurrentUsername();
        }
        return orderRepository.findByCreatedBy(username);
    }

    public Order approveOrder(Long orderId) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setStatus(OrderStatus.APPROVED);
            return orderRepository.save(order);
        }
        return null;
    }

    public void deleteOrder(Long orderId) {
        orderRepository.deleteById(orderId);
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return authentication.getName();
        }
        return "anonymous";
    }
}
