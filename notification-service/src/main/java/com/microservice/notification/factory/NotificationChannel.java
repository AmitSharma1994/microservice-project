package com.microservice.notification.factory;

import com.microservice.notification.dto.NotificationMessage;

/**
 * Notification Channel Interface - Factory Pattern
 * Defines the contract for different notification channels
 */
public interface NotificationChannel {

    void send(NotificationMessage message);

    String getChannelType();
}

