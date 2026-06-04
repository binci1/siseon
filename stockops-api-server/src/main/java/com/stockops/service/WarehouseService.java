package com.stockops.service;

import com.stockops.dto.WarehouseCanCloseResponse;
import com.stockops.entity.Center;
import com.stockops.entity.Inventory;
import com.stockops.entity.InventoryTransfer;
import com.stockops.entity.InventoryTransferStatus;
import com.stockops.entity.Warehouse;
import com.stockops.entity.Inbound;
import com.stockops.entity.InboundItem;
import com.stockops.entity.Warehouse;
import com.stockops.entity.WarehouseStatus;
import com.stockops.exception.InvalidOperationException;
import com.stockops.exception.ResourceNotFoundException;
import com.stockops.repository.InventoryRepository;
import com.stockops.repository.InventoryTransferRepository;
import com.stockops.repository.WarehouseRepository;
import com.stockops.repository.InboundRepository;
import com.stockops.repository.InboundItemRepository;
import com.stockops.repository.WarehouseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

/**
 * Service for Warehouse management.
 *
 * @author StockOps Team
 * @since 2.0
 */
@Service
@Transactional
public class WarehouseService {

    private final WarehouseRepository warehouseRepository;
    private final CenterService centerService;
    private final WarehouseRepository WarehouseRepository;
    private final InventoryRepository inventoryRepository;
    private final InboundRepository inboundRepository;
    private final InboundItemRepository inboundItemRepository;
    private final InventoryTransferRepository inventoryTransferRepository;

    public List<Warehouse> findAll() {
        return warehouseRepository.findAllWithCenter();
    }

    public List<Warehouse> findByCenterId(Long centerId) {
        return warehouseRepository.findByCenterId(centerId);
    }

    public List<Warehouse> findActiveByCenterId(Long centerId) {
        return warehouseRepository.findActiveByCenterId(centerId);
    }

    public Warehouse findById(Long id) {
        return warehouseRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Warehouse not found: " + id));
    }

    public Warehouse create(Long centerId, Warehouse warehouse) {
        Center center = centerService.findById(centerId);

        if (warehouseRepository.existsByCenterIdAndCode(centerId, warehouse.getCode())) {
            throw new InvalidOperationException("Warehouse code already exists in this center: " + warehouse.getCode());
        }

        warehouse.setCenter(center);
        warehouse.setStatus(WarehouseStatus.ACTIVE);
        return warehouseRepository.save(warehouse);
    }

    public Warehouse update(Long id, Warehouse warehouse) {
        Warehouse existing = findById(id);
        existing.setName(warehouse.getName());
        existing.setAddress(warehouse.getAddress());
        existing.setPhone(warehouse.getPhone());
        existing.setStatus(warehouse.getStatus());
        return warehouseRepository.save(existing);
    }

    public void delete(Long id) {
        Warehouse warehouse = findById(id);
        warehouse.setStatus(WarehouseStatus.CLOSED);
        warehouseRepository.save(warehouse);
    }

    /**
     * Checks whether a warehouse can be closed.
     * Validates that no remaining inventory, open inbound drafts, or open transfers exist
     * for Warehouses within the warehouse.
     *
     * @param warehouseId warehouse identifier
     * @return true if the warehouse can be closed
     */
    @Transactional(readOnly = true)
    public boolean canClose(Long warehouseId) {
        Warehouse warehouse = findById(warehouseId);
        if (warehouse.getStatus() == WarehouseStatus.CLOSED) {
            return false;
        }

        List<Long> warehouseIds = WarehouseRepository.findByWarehouseId(warehouseId)
                .stream()
                .map(Warehouse::getId)
                .toList();

        if (warehouseIds.isEmpty()) {
            return true;
        }

        List<Inventory> inventories = inventoryRepository.findAllByWarehouseIdIn(warehouseIds);
        boolean hasInventory = inventories.stream()
                .anyMatch(inv -> nullSafeQuantity(inv.getQuantity()) > 0);
        if (hasInventory) {
            return false;
        }

        List<Inbound> draftInbounds = inboundRepository.findByStatus("DRAFT");
        for (Inbound inbound : draftInbounds) {
            List<InboundItem> items = inboundItemRepository.findByInboundId(inbound.getId());
            boolean targetsWarehouse = items.stream()
                    .anyMatch(item -> warehouseIds.contains(item.getWarehouseId()));
            if (targetsWarehouse) {
                return false;
            }
        }

        for (Long wid : warehouseIds) {
            List<InventoryTransfer> fromTransfers = inventoryTransferRepository.findByFromWarehouseId(wid);
            List<InventoryTransfer> toTransfers = inventoryTransferRepository.findByToWarehouseId(wid);
            boolean hasOpenTransfers = Stream.concat(fromTransfers.stream(), toTransfers.stream())
                    .anyMatch(t -> t.getStatus() == InventoryTransferStatus.REQUESTED);
            if (hasOpenTransfers) {
                return false;
            }
        }

        return true;
    }

    /**
     * Closes a warehouse after validating preconditions.
     * Sets status to CLOSED and records the closure reason and timestamp.
     *
     * @param warehouseId warehouse identifier
     * @param reason closure reason
     * @return closed warehouse
     * @throws ResourceNotFoundException when warehouse does not exist
     * @throws InvalidOperationException when warehouse cannot be closed
     */
    public Warehouse close(Long warehouseId, String reason) {
        if (!canClose(warehouseId)) {
            throw new InvalidOperationException(
                    "Warehouse cannot be closed. Ensure no inventory, open inbounds, or open transfers remain.");
        }
        Warehouse warehouse = findById(warehouseId);
        warehouse.setStatus(WarehouseStatus.CLOSED);
        warehouse.setClosureReason(reason);
        warehouse.setClosedAt(Instant.now());
        return warehouseRepository.save(warehouse);
    }

    /**
     * Returns detailed closure preconditions for a warehouse.
     *
     * @param warehouseId warehouse identifier
     * @return response with canClose flag and specific blocking reasons
     */
    @Transactional(readOnly = true)
    public WarehouseCanCloseResponse getCanCloseResponse(Long warehouseId) {
        Warehouse warehouse = findById(warehouseId);
        if (warehouse.getStatus() == WarehouseStatus.CLOSED) {
            List<String> reasons = List.of("?? ??????");
            return new WarehouseCanCloseResponse(false, reasons, 0, 0, 0);
        }

        List<Long> warehouseIds = WarehouseRepository.findByWarehouseId(warehouseId)
                .stream()
                .map(Warehouse::getId)
                .toList();

        int remainingInventory = 0;
        int openInbounds = 0;
        int openTransfers = 0;
        List<String> reasons = new ArrayList<>();

        if (!warehouseIds.isEmpty()) {
            List<Inventory> inventories = inventoryRepository.findAllByWarehouseIdIn(warehouseIds);
            remainingInventory = (int) inventories.stream()
                    .filter(inv -> nullSafeQuantity(inv.getQuantity()) > 0)
                    .count();
            if (remainingInventory > 0) {
                reasons.add("inventory: " + remainingInventory);
            }

            List<Inbound> draftInbounds = inboundRepository.findByStatus("DRAFT");
            for (Inbound inbound : draftInbounds) {
                List<InboundItem> items = inboundItemRepository.findByInboundId(inbound.getId());
                boolean targetsWarehouse = items.stream()
                        .anyMatch(item -> warehouseIds.contains(item.getWarehouseId()));
                if (targetsWarehouse) {
                    openInbounds++;
                }
            }
            if (openInbounds > 0) {
                reasons.add("inbounds: " + openInbounds);
            }

            for (Long wid : warehouseIds) {
                List<InventoryTransfer> fromTransfers = inventoryTransferRepository.findByFromWarehouseId(wid);
                List<InventoryTransfer> toTransfers = inventoryTransferRepository.findByToWarehouseId(wid);
                long count = Stream.concat(fromTransfers.stream(), toTransfers.stream())
                        .filter(t -> t.getStatus() == InventoryTransferStatus.REQUESTED)
                        .count();
                openTransfers += (int) count;
            }
            if (openTransfers > 0) {
                reasons.add("transfers: " + openTransfers);
            }
        }

        boolean canClose = reasons.isEmpty();
        return new WarehouseCanCloseResponse(canClose, reasons, remainingInventory, openInbounds, openTransfers);
    }

    private int nullSafeQuantity(Integer quantity) {
        return quantity == null ? 0 : quantity;
    }

    public WarehouseService(final WarehouseRepository warehouseRepository, final CenterService centerService, final WarehouseRepository WarehouseRepository, final InventoryRepository inventoryRepository, final InboundRepository inboundRepository, final InboundItemRepository inboundItemRepository, final InventoryTransferRepository inventoryTransferRepository) {
        this.warehouseRepository = warehouseRepository;
        this.centerService = centerService;
        this.WarehouseRepository = WarehouseRepository;
        this.inventoryRepository = inventoryRepository;
        this.inboundRepository = inboundRepository;
        this.inboundItemRepository = inboundItemRepository;
        this.inventoryTransferRepository = inventoryTransferRepository;
    }
}
