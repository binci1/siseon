package com.stockops.repository;

import com.stockops.entity.InventoryTransfer;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for inventory transfer persistence.
 *
 * @author StockOps Team
 * @since 2.0
 */
@Repository
public interface InventoryTransferRepository extends JpaRepository<InventoryTransfer, Long> {

    List<InventoryTransfer> findByStatus(String status);

    List<InventoryTransfer> findByFromWarehouseId(Long fromWarehouseId);

    List<InventoryTransfer> findByToWarehouseId(Long toWarehouseId);

    List<InventoryTransfer> findByProductId(Long productId);
}
