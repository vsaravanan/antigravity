package com.saravanjs.hello.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.config
 * @class RedisConfiguration
 */
@Configuration
@EnableConfigurationProperties(RedisProperties.class)
public class RedisConfiguration {
}