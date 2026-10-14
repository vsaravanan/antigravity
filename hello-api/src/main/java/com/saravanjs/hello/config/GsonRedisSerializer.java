package com.saravanjs.hello.config;

/**
 * @author Sarav on 16 Jul 2026
 * @project govtech
 * @package com.saravanjs.hello.config
 * @class GsonRedisSerializer
 */

import com.google.gson.Gson;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.SerializationException;

import java.nio.charset.StandardCharsets;

@RequiredArgsConstructor
public class GsonRedisSerializer<T> implements RedisSerializer<T> {

    private final Gson gson;
    private final Class<T> type;

    @Override
    public byte[] serialize(T value) throws SerializationException {

        if (value == null) {
            return null;
        }

        return gson.toJson(value)
                .getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public T deserialize(byte[] bytes) throws SerializationException {

        if (bytes == null || bytes.length == 0) {
            return null;
        }

        return gson.fromJson(
                new String(bytes, StandardCharsets.UTF_8),
                type);
    }

}