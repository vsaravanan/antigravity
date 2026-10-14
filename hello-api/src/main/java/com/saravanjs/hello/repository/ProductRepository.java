package com.saravanjs.hello.repository;

import com.google.gson.Gson;
import com.saravanjs.hello.model.ProductRecord;
import lombok.RequiredArgsConstructor;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Repository;

import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.repository
 * @class ProductRepository
 */

@Repository
@RequiredArgsConstructor
public class ProductRepository {

    private static final String STOCK = "stock";
    private static final String CART_PREFIX = "cart:";

    private final RedissonClient redisson;
    private final RedisTemplate<String, ProductRecord> redis;
    private final Gson gson;
    private final Object buyLock = new Object();


    public ProductRecord buy(String user)  {

        while (true) {
            try {
                Set<ProductRecord> products = getStock();

                if (products.isEmpty()) {
                    return null;
                }

                // Convert only for random selection
                ProductRecord product =
                        products.stream()
                                .skip(ThreadLocalRandom.current()
                                        .nextInt(products.size()))
                                .findFirst()
                                .orElseThrow();

//            String lockKey = "lock:" + product.name();
//
//            Boolean locked =
//                    redis.opsForValue().setIfAbsent(
//                            lockKey,
//                            product,
//                            Duration.ofSeconds(5));
//            if (!Boolean.TRUE.equals(locked)) {
//                continue;
//            }


                RLock lock =
                        redisson.getLock(
                                "lock:" + product.name());


                if (!lock.tryLock(1, 30, TimeUnit.SECONDS)) {

                    continue;
                }

                try {

                    if (!stockContains(product)) {
                        continue;
                    }

                    if (!removeFromStock(product)) {
                        continue;
                    }

                    addToCart(user, product);

                    return product;

                } finally {
//                   redis.delete(lockKey);
                    if (lock.isLocked() && lock.isHeldByCurrentThread()) {
                        lock.unlock();
                    }
                }
            } catch (Exception ex) {

                Thread.currentThread().interrupt();

                throw new IllegalStateException(
                        "Interrupted while acquiring Redis lock", ex);
            }
        }
    }


    private Set<ProductRecord> filterSet(String condition) {
        Set<ProductRecord> products =
                redis.opsForSet().members(condition);

        return products == null
                ? Set.of()
                : products;

//        return values.stream()
//                .map(v -> gson.fromJson(v, ProductRecord.class))
//                .collect(Collectors.toSet());
    }

    public Set<ProductRecord> getCart(String user) {
        return filterSet(CART_PREFIX + user);
    }

    public Set<ProductRecord> getStock() {
        return filterSet(STOCK);
    }

    public void clear() {
        redis.delete(STOCK);

        Set<String> keys = redis.keys("cart:*");

        if (keys != null && !keys.isEmpty()) {
            redis.delete(keys);
        }
    }

    public boolean stockContains(ProductRecord product) {

        Boolean exists = redis.opsForSet().isMember(
                STOCK,
                product);

        return Boolean.TRUE.equals(exists);
    }

    public void addStock(ProductRecord product) {

        redis.opsForSet().add(
                STOCK,
                product);
    }

    public boolean removeFromStock(ProductRecord product) {

        Long removed = redis.opsForSet().remove(
                STOCK,
                product);

        return removed != null && removed > 0;
    }

    private void addToCart(
            String user,
            ProductRecord product) {

        redis.opsForSet().add(
                CART_PREFIX + user,
                product);
    }

    private ProductRecord getRandomProduct(
            Set<ProductRecord> products) {

        int random = ThreadLocalRandom.current()
                .nextInt(products.size());

        int index = 0;

        for (ProductRecord product : products) {

            if (index++ == random) {
                return product;
            }
        }

        return null;
    }

}