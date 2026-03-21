package com.microservice.order.mapper;

import com.microservice.order.dto.OrderItemResponse;
import com.microservice.order.dto.OrderResponse;
import com.microservice.order.entity.Order;
import com.microservice.order.entity.OrderItem;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-03-21T21:16:38+0530",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 17.0.10 (Oracle Corporation)"
)
@Component
public class OrderMapperImpl implements OrderMapper {

    @Override
    public OrderResponse toResponse(Order order) {
        if ( order == null ) {
            return null;
        }

        OrderResponse.OrderResponseBuilder orderResponse = OrderResponse.builder();

        orderResponse.id( order.getId() );
        orderResponse.userId( order.getUserId() );
        orderResponse.items( toItemResponseList( order.getItems() ) );
        orderResponse.totalAmount( order.getTotalAmount() );
        orderResponse.status( order.getStatus() );
        orderResponse.paymentMethod( order.getPaymentMethod() );
        orderResponse.paymentReference( order.getPaymentReference() );
        orderResponse.createdAt( order.getCreatedAt() );
        orderResponse.updatedAt( order.getUpdatedAt() );

        return orderResponse.build();
    }

    @Override
    public OrderItemResponse toItemResponse(OrderItem item) {
        if ( item == null ) {
            return null;
        }

        OrderItemResponse.OrderItemResponseBuilder orderItemResponse = OrderItemResponse.builder();

        orderItemResponse.id( item.getId() );
        orderItemResponse.productId( item.getProductId() );
        orderItemResponse.quantity( item.getQuantity() );
        orderItemResponse.price( item.getPrice() );

        return orderItemResponse.build();
    }

    @Override
    public List<OrderItemResponse> toItemResponseList(List<OrderItem> items) {
        if ( items == null ) {
            return null;
        }

        List<OrderItemResponse> list = new ArrayList<OrderItemResponse>( items.size() );
        for ( OrderItem orderItem : items ) {
            list.add( toItemResponse( orderItem ) );
        }

        return list;
    }
}
