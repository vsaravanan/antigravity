package com.saravanjs.hello.config;

import com.google.gson.Gson;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.config
 * @class GsonConfig
 */
@Configuration
public class GsonConfig {

    @Bean
    public Gson gson() {
        return new Gson();
    }

}
