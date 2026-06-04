package com.stockops.dto;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Inbound item response payload.
 *
 * @param id inbound item identifier
 * @param inboundId parent inbound identifier
 * @param productId product identifier
 * @param productName product display name
 * @param lotNumber lot number
 * @param expiryDate expiry date
 * @param quantity inbound quantity
 * @param warehouseId destination Warehouse identifier
 * @param warehouseCode destination Warehouse code
 * @param createdAt creation timestamp
 * @author StockOps Team
 * @since 1.0
 */
public record InboundItemDTO(
        Long id,
        Long inboundId,
        Long productId,
        String productName,
        String lotNumber,
        LocalDate expiryDate,
        int quantity,
        Long warehouseId,
        String warehouseCode,
        Instant createdAt
) {
}
