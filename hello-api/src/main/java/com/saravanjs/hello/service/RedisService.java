package com.saravanjs.hello.service;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.service
 * @class RedisService
 */


import com.saravanjs.hello.model.ProductRecord;
import com.saravanjs.hello.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
public class RedisService {


    private final ProductRepository repository;

    public void init() {

        repository.clear();


//        for (int i = 1; i <= 10; i++) {
//            repository.addStock(
//                    new ProductRecord("Product" + i));
//        }

        IntStream.rangeClosed(1, 10)
                .mapToObj(i -> new ProductRecord("Product" + i))
                .forEach(repository::addStock);

    }

    public ProductRecord buy(String user) {

        return repository.buy(user);

    }

    public Set<ProductRecord> getCart(String user) {

        return repository.getCart(user);

    }

    public Set<ProductRecord> getStock() {

        return repository.getStock();

    }

}