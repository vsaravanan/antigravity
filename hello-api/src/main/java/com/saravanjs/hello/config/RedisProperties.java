package com.saravanjs.hello.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.config
 * @class RedisProperties
 */
@ConfigurationProperties(prefix = "spring.data.redis")
@ConditionalOnProperty(
        prefix = "app.redis",
        name = "enabled",
        havingValue = "true")
public record RedisProperties(

        String host,
        int port

) {
}