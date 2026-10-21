package com.saravanjs.hello.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String productName;
    private int quantity;
    
    @Enumerated(EnumType.STRING)
    private OrderStatus status;
    
    private String createdBy;
}
