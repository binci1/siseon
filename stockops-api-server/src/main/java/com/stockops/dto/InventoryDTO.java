package com.stockops.dto;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Inventory response payload with denormalized product, Warehouse, and lot details.
 *
 * @param id inventory identifier
 * @param productId product identifier
 * @param productBarcode product barcode
 * @param productName product name
 * @param warehouseId Warehouse identifier
 * @param warehouseCode Warehouse code
 * @param warehouseName Warehouse name
 * @param lotId lot identifier
 * @param lotNumber lot number
 * @param expiryDate lot expiry date
 * @param quantity available quantity
 * @param reservedQuantity reserved quantity
 * @param status inventory status (ACTIVE, RESERVED, QUARANTINE, EXPIRED)
 * @param createdAt creation timestamp
 * @param updatedAt last update timestamp
 * @author StockOps Team
 * @since 1.0
 */
public record InventoryDTO(
        Long id,
        Long productId,
        String productBarcode,
        String productName,
        Long warehouseId,
        String warehouseCode,
        String warehouseName,
        Long lotId,
        String lotNumber,
        LocalDate expiryDate,
        int quantity,
        int reservedQuantity,
        String status,
        Instant createdAt,
        Instant updatedAt
) {
}
