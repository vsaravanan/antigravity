package com.saravanjs.hello.service;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService implements UserDetailsService {

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        if ("kannan".equals(username)) {
            return User.builder()
                    .username("kannan")
                    .password(passwordEncoder.encode("kannan"))
                    .authorities(List.of(new SimpleGrantedAuthority("ROLE_MAKER")))
                    .build();
        } else if ("rakesh".equals(username)) {
            return User.builder()
                    .username("rakesh")
                    .password(passwordEncoder.encode("rakesh"))
                    .authorities(List.of(new SimpleGrantedAuthority("ROLE_CHECKER")))
                    .build();
        }
        throw new UsernameNotFoundException("User not found: " + username);
    }
}