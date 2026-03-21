package com.microservice.notification.factory;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Notification Channel Factory - Factory Pattern
 * Selects appropriate notification channel based on channel type
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationChannelFactory {

    private final List<NotificationChannel> channels;

    public NotificationChannel getChannel(String channelType) {
        Map<String, NotificationChannel> channelMap = channels.stream()
                .collect(Collectors.toMap(NotificationChannel::getChannelType, Function.identity()));

        NotificationChannel channel = channelMap.get(channelType.toUpperCase());
        if (channel == null) {
            log.warn("Unsupported notification channel: {}. Falling back to EMAIL.", channelType);
            return channelMap.get("EMAIL");
        }
        return channel;
    }
}

