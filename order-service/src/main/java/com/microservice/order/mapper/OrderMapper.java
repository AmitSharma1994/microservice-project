package com.microservice.order.mapper;

import com.microservice.order.dto.OrderItemResponse;
import com.microservice.order.dto.OrderResponse;
import com.microservice.order.entity.Order;
import com.microservice.order.entity.OrderItem;
import org.mapstruct.Mapper;

import java.util.List;

/**
 * MapStruct Mapper for Order
 */
@Mapper(componentModel = "spring")
public interface OrderMapper {

    OrderResponse toResponse(Order order);

    OrderItemResponse toItemResponse(OrderItem item);

    List<OrderItemResponse> toItemResponseList(List<OrderItem> items);
}

