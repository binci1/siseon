package com.stockops.service;

import com.stockops.dto.InventoryDTO;
import com.stockops.dto.InventoryTransactionDTO;
import com.stockops.entity.Inventory;
import com.stockops.entity.InventoryTransaction;
import com.stockops.entity.Lot;
import com.stockops.entity.Warehouse;
import com.stockops.entity.Product;
import com.stockops.exception.ResourceNotFoundException;
import com.stockops.repository.InventoryRepository;
import com.stockops.repository.InventoryTransactionRepository;
import com.stockops.repository.LotRepository;
import com.stockops.repository.WarehouseRepository;
import com.stockops.repository.ProductRepository;
import com.stockops.security.ScopeGuard;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Inventory query service for read-only inventory and transaction lookups.
 *
 * @author StockOps Team
 * @since 1.0
 * @see InventoryRepository
 * @see InventoryTransactionRepository
 */
@Service
@Transactional(readOnly = true)
public class InventoryQueryService {

    private final InventoryRepository inventoryRepository;
    private final InventoryTransactionRepository transactionRepository;
    private final ProductRepository productRepository;
    private final WarehouseRepository WarehouseRepository;
    private final LotRepository lotRepository;
    private final ScopeGuard scopeGuard;

    /**
     * Returns all inventory rows visible to the current scope.
     *
     * @return filtered inventory list
     */
    public List<InventoryDTO> getAllInventory() {
        return toInventoryDtos(scopeGuard.filterByWarehouseScope(inventoryRepository.findAll(), Inventory::getWarehouseId));
    }

    /**
     * Returns inventory rows for a product, filtered to the current scope.
     *
     * @param productId product identifier
     * @return filtered inventory list
     */
    public List<InventoryDTO> getInventoryByProduct(final Long productId) {
        return toInventoryDtos(scopeGuard.filterByWarehouseScope(
                inventoryRepository.findByProductId(productId),
                Inventory::getWarehouseId));
    }

    /**
     * Returns inventory rows for a Warehouse when the Warehouse is in scope.
     *
     * @param warehouseId Warehouse identifier
     * @return filtered inventory list, or an empty list when the Warehouse is outside scope
     */
    public List<InventoryDTO> getInventoryByWarehouse(final Long warehouseId) {
        if (!scopeGuard.canAccessWarehouse(warehouseId)) {
            return List.of();
        }
        return toInventoryDtos(inventoryRepository.findByWarehouseId(warehouseId));
    }

    /**
     * Returns inventory rows for a lot, filtered to the current scope.
     *
     * @param lotId lot identifier
     * @return filtered inventory list
     */
    public List<InventoryDTO> getInventoryByLot(final Long lotId) {
        return toInventoryDtos(scopeGuard.filterByWarehouseScope(
                inventoryRepository.findByLotId(lotId),
                Inventory::getWarehouseId));
    }

    /**
     * Returns a single inventory row and rejects direct access outside scope.
     *
     * @param id inventory identifier
     * @return inventory DTO
     */
    public InventoryDTO getInventoryById(final Long id) {
        final Inventory inventory = inventoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory not found: " + id));
        scopeGuard.assertWarehouseAccess(inventory.getWarehouseId());
        return toDTO(inventory);
    }

    public List<InventoryTransactionDTO> getTransactionHistory(final Long productId,
                                                               final Long warehouseId,
                                                               final Long lotId) {
        if (warehouseId != null && !scopeGuard.canAccessWarehouse(warehouseId)) {
            return List.of();
        }

        final List<InventoryTransaction> transactions;
        if (productId != null) {
            transactions = transactionRepository.findByProductIdOrderByCreatedAtDesc(productId);
        } else if (warehouseId != null) {
            transactions = transactionRepository.findByWarehouseIdOrderByCreatedAtDesc(warehouseId);
        } else if (lotId != null) {
            transactions = transactionRepository.findByLotIdOrderByCreatedAtDesc(lotId);
        } else {
            transactions = transactionRepository.findAll();
            transactions.sort(Comparator.comparing(
                    InventoryTransaction::getCreatedAt,
                    Comparator.nullsLast(Comparator.reverseOrder())));
        }

        return scopeGuard.filterByWarehouseScope(transactions, InventoryTransaction::getWarehouseId).stream()
                .map(this::toTransactionDTO)
                .toList();
    }

    /**
     * Returns the most recent visible inventory transactions.
     *
     * @param limit maximum number of rows to return
     * @return filtered recent transactions
     */
    public List<InventoryTransactionDTO> getRecentTransactions(final int limit) {
        return scopeGuard.filterByWarehouseScope(
                        transactionRepository.findTop50ByOrderByCreatedAtDesc(),
                        InventoryTransaction::getWarehouseId)
                .stream()
                .limit(Math.max(0, limit))
                .map(this::toTransactionDTO)
                .toList();
    }

    private List<InventoryDTO> toInventoryDtos(final List<Inventory> inventory) {
        return inventory.stream().map(this::toDTO).toList();
    }

    private InventoryDTO toDTO(final Inventory inventory) {
        final Product product = productRepository.findById(inventory.getProductId()).orElse(null);
        final Warehouse Warehouse = WarehouseRepository.findById(inventory.getWarehouseId()).orElse(null);
        final Lot lot = inventory.getLotId() == null ? null : lotRepository.findById(inventory.getLotId()).orElse(null);

        return new InventoryDTO(
                inventory.getId(),
                inventory.getProductId(),
                product == null ? null : product.getBarcode(),
                product == null ? null : product.getName(),
                inventory.getWarehouseId(),
                Warehouse == null ? null : Warehouse.getCode(),
                Warehouse == null ? null : Warehouse.getName(),
                inventory.getLotId(),
                lot == null ? null : lot.getLotNumber(),
                lot == null ? null : lot.getExpiryDate(),
                nullSafeInt(inventory.getQuantity()),
                nullSafeInt(inventory.getReservedQuantity()),
                inventory.getStatus() == null ? "ACTIVE" : inventory.getStatus().name(),
                inventory.getCreatedAt(),
                inventory.getUpdatedAt());
    }

    private InventoryTransactionDTO toTransactionDTO(final InventoryTransaction transaction) {
        final Product product = productRepository.findById(transaction.getProductId()).orElse(null);
        final Warehouse Warehouse = WarehouseRepository.findById(transaction.getWarehouseId()).orElse(null);
        final Lot lot = transaction.getLotId() == null ? null : lotRepository.findById(transaction.getLotId()).orElse(null);

        return new InventoryTransactionDTO(
                transaction.getId(),
                transaction.getType(),
                transaction.getProductId(),
                product == null ? null : product.getName(),
                transaction.getWarehouseId(),
                Warehouse == null ? null : Warehouse.getCode(),
                transaction.getLotId(),
                lot == null ? null : lot.getLotNumber(),
                nullSafeInt(transaction.getQuantity()),
                nullSafeInt(transaction.getBeforeQuantity()),
                nullSafeInt(transaction.getAfterQuantity()),
                transaction.getReferenceId(),
                transaction.getType(),
                transaction.getCreatedBy(),
                transaction.getCreatedAt());
    }

    private int nullSafeInt(final Integer value) {
        return value == null ? 0 : value;
    }

    public InventoryQueryService(final InventoryRepository inventoryRepository, final InventoryTransactionRepository transactionRepository, final ProductRepository productRepository, final WarehouseRepository WarehouseRepository, final LotRepository lotRepository, final ScopeGuard scopeGuard) {
        this.inventoryRepository = inventoryRepository;
        this.transactionRepository = transactionRepository;
        this.productRepository = productRepository;
        this.WarehouseRepository = WarehouseRepository;
        this.lotRepository = lotRepository;
        this.scopeGuard = scopeGuard;
    }
}
