package com.saravanjs.hello.config;

import com.google.gson.Gson;
import com.saravanjs.hello.model.ProductRecord;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.config
 * @class RedisConfig
 */
@Configuration
@RequiredArgsConstructor
@ConditionalOnProperty(
        prefix = "app.redis",
        name = "enabled",
        havingValue = "true")
public class RedisConfig {

    private final Gson gson;

    @Bean
    public RedisTemplate<String, ProductRecord> redisTemplate(
            RedisConnectionFactory connectionFactory) {

        RedisTemplate<String, ProductRecord> template = new RedisTemplate<>();

        template.setConnectionFactory(connectionFactory);

        StringRedisSerializer keySerializer =
                new StringRedisSerializer();

        GsonRedisSerializer<ProductRecord> valueSerializer =
                new GsonRedisSerializer<>(
                        gson,
                        ProductRecord.class);

        template.setKeySerializer(keySerializer);
        template.setHashKeySerializer(keySerializer);

        template.setValueSerializer(valueSerializer);
        template.setHashValueSerializer(valueSerializer);

        template.setDefaultSerializer(valueSerializer);

        // Recommended so every collection uses the same serializer
        template.setEnableDefaultSerializer(true);

        template.afterPropertiesSet();


        return template;
    }
}