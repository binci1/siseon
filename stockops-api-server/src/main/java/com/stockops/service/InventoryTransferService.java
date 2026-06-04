package com.stockops.service;

import com.stockops.dto.CreateInventoryTransferRequest;
import com.stockops.dto.InventoryTransferDTO;
import com.stockops.entity.InventoryTransfer;
import com.stockops.entity.InventoryTransferStatus;
import com.stockops.entity.Warehouse;
import com.stockops.entity.User;
import com.stockops.entity.WarehouseStatus;
import com.stockops.exception.InvalidOperationException;
import com.stockops.exception.ResourceNotFoundException;
import com.stockops.repository.InventoryTransferRepository;
import com.stockops.repository.WarehouseRepository;
import com.stockops.repository.UserRepository;
import com.stockops.repository.WarehouseRepository;
import com.stockops.security.ScopeGuard;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for inventory transfer management.
 * Handles creation, completion, and cancellation of stock transfers between Warehouses.
 * Transfer completion atomically deducts from source and adds to destination inventory.
 *
 * @author StockOps Team
 * @since 2.0
 * @see InventoryTransferRepository
 * @see InventoryService
 */
@Service
public class InventoryTransferService {

    private final InventoryTransferRepository transferRepository;
    private final InventoryService inventoryService;
    private final WarehouseRepository WarehouseRepository;
    private final WarehouseRepository warehouseRepository;
    private final UserRepository userRepository;
    private final ScopeGuard scopeGuard;

    /**
     * Creates a new inventory transfer request.
     *
     * @param request transfer creation payload
     * @param userId requesting operator identifier
     * @return created transfer response
     * @throws ResourceNotFoundException when a Warehouse does not exist
     * @throws InvalidOperationException when Warehouses are in different centers or quantity is invalid
     */
    @Transactional
    public InventoryTransferDTO createTransfer(final CreateInventoryTransferRequest request, final Long userId) {
        validateWarehousesSameCenter(request.fromWarehouseId(), request.toWarehouseId());
        scopeGuard.assertWarehouseAccess(request.fromWarehouseId());
        scopeGuard.assertWarehouseAccess(request.toWarehouseId());

        if (request.quantity() <= 0) {
            throw new InvalidOperationException("Quantity must be greater than zero");
        }

        final InventoryTransfer transfer = new InventoryTransfer();
        transfer.setProductId(request.productId());
        transfer.setLotId(request.lotId());
        transfer.setFromWarehouseId(request.fromWarehouseId());
        transfer.setToWarehouseId(request.toWarehouseId());
        transfer.setQuantity(request.quantity());
        transfer.setStatus(InventoryTransferStatus.REQUESTED);
        transfer.setRequestedBy(userId);
        transfer.setNotes(request.notes());

        return toDto(transferRepository.save(transfer));
    }

    /**
     * Retrieves all inventory transfers visible to the current user.
     *
     * @return list of transfer responses
     */
    @Transactional(readOnly = true)
    public List<InventoryTransferDTO> findAll() {
        return filterScopedTransfers(transferRepository.findAll());
    }

    /**
     * Retrieves an inventory transfer by identifier.
     *
     * @param id transfer identifier
     * @return transfer response
     * @throws ResourceNotFoundException when the transfer does not exist
     */
    @Transactional(readOnly = true)
    public InventoryTransferDTO findById(final Long id) {
        final InventoryTransfer transfer = transferRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transfer not found: " + id));
        assertTransferAccess(transfer);
        return toDto(transfer);
    }

    /**
     * Completes a requested transfer by atomically moving stock.
     * Deducts from source inventory and adds to destination inventory.
     *
     * @param id transfer identifier
     * @param userId completing operator identifier
     * @return completed transfer response
     * @throws ResourceNotFoundException when the transfer does not exist
     * @throws InvalidOperationException when the transfer is not in REQUESTED status
     */
    @Transactional
    public InventoryTransferDTO completeTransfer(final Long id, final Long userId) {
        final InventoryTransfer transfer = transferRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transfer not found: " + id));
        assertTransferAccess(transfer);

        if (transfer.getStatus() != InventoryTransferStatus.REQUESTED) {
            throw new InvalidOperationException("Only REQUESTED transfers can be completed");
        }

        final Warehouse fromWarehouse = WarehouseRepository.findById(transfer.getFromWarehouseId())
                .orElseThrow(() -> new ResourceNotFoundException("Source Warehouse not found: " + transfer.getFromWarehouseId()));
        final Warehouse toWarehouse = WarehouseRepository.findById(transfer.getToWarehouseId())
                .orElseThrow(() -> new ResourceNotFoundException("Destination Warehouse not found: " + transfer.getToWarehouseId()));
        assertWarehouseWarehouseNotClosed(fromWarehouse);
        assertWarehouseWarehouseNotClosed(toWarehouse);

        inventoryService.decreaseStock(
                transfer.getProductId(),
                transfer.getFromWarehouseId(),
                transfer.getLotId(),
                transfer.getQuantity(),
                "TRANSFER",
                transfer.getId(),
                userId
        );

        inventoryService.increaseStock(
                transfer.getProductId(),
                transfer.getToWarehouseId(),
                transfer.getLotId(),
                transfer.getQuantity(),
                "TRANSFER",
                transfer.getId(),
                userId
        );

        transfer.setStatus(InventoryTransferStatus.COMPLETED);
        transfer.setCompletedBy(userId);

        return toDto(transferRepository.save(transfer));
    }

    /**
     * Cancels a requested transfer without moving stock.
     *
     * @param id transfer identifier
     * @param userId cancelling operator identifier
     * @return cancelled transfer response
     * @throws ResourceNotFoundException when the transfer does not exist
     * @throws InvalidOperationException when the transfer is not in REQUESTED status
     */
    @Transactional
    public InventoryTransferDTO cancelTransfer(final Long id, final Long userId) {
        final InventoryTransfer transfer = transferRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transfer not found: " + id));
        assertTransferAccess(transfer);

        if (transfer.getStatus() != InventoryTransferStatus.REQUESTED) {
            throw new InvalidOperationException("Only REQUESTED transfers can be cancelled");
        }

        transfer.setStatus(InventoryTransferStatus.CANCELLED);
        transfer.setCompletedBy(userId);

        return toDto(transferRepository.save(transfer));
    }

    private void validateWarehousesSameCenter(final Long fromWarehouseId, final Long toWarehouseId) {
        if (fromWarehouseId.equals(toWarehouseId)) {
            throw new InvalidOperationException("Source and destination Warehouses must be different");
        }

        final Warehouse fromWarehouse = WarehouseRepository.findById(fromWarehouseId)
                .orElseThrow(() -> new ResourceNotFoundException("Source Warehouse not found: " + fromWarehouseId));
        final Warehouse toWarehouse = WarehouseRepository.findById(toWarehouseId)
                .orElseThrow(() -> new ResourceNotFoundException("Destination Warehouse not found: " + toWarehouseId));

        assertWarehouseWarehouseNotClosed(fromWarehouse);
        assertWarehouseWarehouseNotClosed(toWarehouse);

        final Long fromCenterId = resolveCenterId(fromWarehouse);
        final Long toCenterId = resolveCenterId(toWarehouse);

        if (fromCenterId == null || toCenterId == null || !fromCenterId.equals(toCenterId)) {
            throw new InvalidOperationException("Transfers are only allowed between Warehouses in the same center");
        }
    }

    private void assertWarehouseWarehouseNotClosed(final Warehouse Warehouse) {
        if (Warehouse != null && Warehouse.getStatus() == WarehouseStatus.CLOSED) {
            throw new InvalidOperationException(
                    "Transfer not allowed for closed warehouse: " + Warehouse.getName());
        }
    }

    private Long resolveCenterId(final Warehouse Warehouse) {
        if (Warehouse != null && Warehouse.getCenter() != null) {
            return Warehouse.getCenter().getId();
        }
        return null;
    }

    private void assertTransferAccess(final InventoryTransfer transfer) {
        scopeGuard.assertWarehouseAccess(transfer.getFromWarehouseId());
        scopeGuard.assertWarehouseAccess(transfer.getToWarehouseId());
    }

    private List<InventoryTransferDTO> filterScopedTransfers(final List<InventoryTransfer> transfers) {
        return transfers.stream()
                .filter(transfer -> scopeGuard.canAccessWarehouse(transfer.getFromWarehouseId())
                        && scopeGuard.canAccessWarehouse(transfer.getToWarehouseId()))
                .map(this::toDto)
                .toList();
    }

    private InventoryTransferDTO toDto(final InventoryTransfer transfer) {
        return new InventoryTransferDTO(
                transfer.getId(),
                transfer.getProductId(),
                transfer.getLotId(),
                transfer.getFromWarehouseId(),
                transfer.getToWarehouseId(),
                transfer.getQuantity(),
                transfer.getStatus(),
                transfer.getRequestedBy(),
                findUserName(transfer.getRequestedBy()),
                transfer.getCompletedBy(),
                findUserName(transfer.getCompletedBy()),
                transfer.getNotes(),
                transfer.getCreatedAt(),
                transfer.getUpdatedAt()
        );
    }

    private String findUserName(final Long userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findById(userId)
                .map(User::getName)
                .orElse(null);
    }

    public InventoryTransferService(final InventoryTransferRepository transferRepository, final InventoryService inventoryService, final WarehouseRepository WarehouseRepository, final WarehouseRepository warehouseRepository, final UserRepository userRepository, final ScopeGuard scopeGuard) {
        this.transferRepository = transferRepository;
        this.inventoryService = inventoryService;
        this.WarehouseRepository = WarehouseRepository;
        this.warehouseRepository = warehouseRepository;
        this.userRepository = userRepository;
        this.scopeGuard = scopeGuard;
    }
}
