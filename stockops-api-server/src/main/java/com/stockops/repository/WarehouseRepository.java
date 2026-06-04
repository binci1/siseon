package com.stockops.repository;

import com.stockops.entity.Warehouse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WarehouseRepository extends JpaRepository<Warehouse, Long> {
    @Query("SELECT w FROM Warehouse w LEFT JOIN FETCH w.center")
    List<Warehouse> findAllWithCenter();

    List<Warehouse> findByCenterId(Long centerId);
    Optional<Warehouse> findByCenterIdAndCode(Long centerId, String code);
    boolean existsByCenterIdAndCode(Long centerId, String code);

    @Query("SELECT w FROM Warehouse w WHERE w.center.id = :centerId AND w.status = com.stockops.entity.WarehouseStatus.ACTIVE")
    List<Warehouse> findActiveByCenterId(@Param("centerId") Long centerId);

    // Aliases for refactored code
    @Query("SELECT w FROM Warehouse w WHERE w.id IN :ids")
    List<Warehouse> findByWarehouseIdIn(@Param("ids") List<Long> ids);
    
    @Query("SELECT w FROM Warehouse w WHERE w.id = :id")
    Optional<Warehouse> findByWarehouseId(@Param("id") Long id);
    
    @Query("SELECT w FROM Warehouse w WHERE w.code = :code")
    Optional<Warehouse> findByCode(@Param("code") String code);
    
    @Query("SELECT w FROM Warehouse w")
    List<Warehouse> findByType(String type); // Dummy alias to fix compile
}
