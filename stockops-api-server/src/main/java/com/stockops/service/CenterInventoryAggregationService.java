package com.stockops.service;

import com.stockops.entity.Inventory;
import com.stockops.entity.Warehouse;
import com.stockops.entity.Warehouse;
import com.stockops.repository.InventoryRepository;
import com.stockops.repository.WarehouseRepository;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service for Center-level inventory aggregation.
 *
 * @author StockOps Team
 * @since 2.0
 */
@Service
@Transactional(readOnly = true)
public class CenterInventoryAggregationService {

    private final WarehouseService warehouseService;
    private final WarehouseRepository WarehouseRepository;
    private final InventoryRepository inventoryRepository;

    /**
     * Get aggregated inventory for a center (sum of all warehouses).
     * Cached for 120 seconds; evicted on any stock mutation.
     *
     * @param centerId center identifier
     * @return aggregated inventory summary
     */
    @Cacheable(value = "center::inventory", key = "#centerId")
    public Map<String, Object> getCenterInventorySummary(Long centerId) {
        List<Warehouse> warehouses = warehouseService.findByCenterId(centerId);

        Map<String, Object> summary = new HashMap<>();
        summary.put("centerId", centerId);
        summary.put("warehouseCount", warehouses.size());

        int totalQuantity = 0;
        int totalItems = 0;

        for (Warehouse warehouse : warehouses) {
            List<Long> warehouseIds = List.of(warehouse.getId());
            if (!warehouseIds.isEmpty()) {
                List<Inventory> inventories = inventoryRepository.findAllByWarehouseIdIn(warehouseIds);
                for (Inventory inv : inventories) {
                    totalQuantity += inv.getQuantity();
                    totalItems++;
                }
            }
        }

        summary.put("totalQuantity", totalQuantity);
        summary.put("totalItems", totalItems);

        return summary;
    }

    public CenterInventoryAggregationService(final WarehouseService warehouseService, final WarehouseRepository WarehouseRepository, final InventoryRepository inventoryRepository) {
        this.warehouseService = warehouseService;
        this.WarehouseRepository = WarehouseRepository;
        this.inventoryRepository = inventoryRepository;
    }
}
