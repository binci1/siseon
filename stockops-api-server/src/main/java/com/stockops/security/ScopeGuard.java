package com.stockops.security;

import com.stockops.entity.Warehouse;
import com.stockops.exception.ResourceNotFoundException;
import com.stockops.exception.ForbiddenException;
import com.stockops.repository.WarehouseRepository;
import com.stockops.repository.WarehouseRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;

/**
 * Shared scope enforcement helper for service/query-layer authorization.
 *
 * @author StockOps Team
 * @since 2.0
 */
@Component
public class ScopeGuard {

    private final WarehouseRepository WarehouseRepository;
    private final WarehouseRepository warehouseRepository;

    /**
     * Asserts access to a center-scoped resource.
     *
     * @param centerId center identifier
     * @throws ForbiddenException when the current user is outside the requested scope
     */
    public void assertCenterAccess(final Long centerId) {
        if (!currentScopeProfile().canAccessCenter(centerId)) {
            throw new ForbiddenException("Access denied for center: " + centerId);
        }
    }

    public void assertAdminAccess() {
        if (!currentScopeProfile().global()) {
            throw new ForbiddenException("Access denied for admin scope");
        }
    }

    public void assertStoreAccess(final Long storeId) {
        assertWarehouseAccess(storeId);
    }

    /**
     * Asserts access to a Warehouse-scoped resource by resolving its warehouse and center hierarchy.
     *
     * @param warehouseId Warehouse identifier
     * @throws ResourceNotFoundException when the Warehouse does not exist
     * @throws ForbiddenException when the current user is outside the requested scope
     */
    public void assertWarehouseAccess(final Long warehouseId) {
        final WarehouseScope warehouseScope = loadWarehouseScopes(List.of(warehouseId)).get(warehouseId);
        if (warehouseScope == null) {
            throw new ResourceNotFoundException("Warehouse not found: " + warehouseId);
        }
        if (!canAccessScope(currentScopeProfile(), warehouseScope.centerId(), warehouseScope.warehouseId())) {
            throw new ForbiddenException("Access denied for Warehouse: " + warehouseId);
        }
    }

    /**
     * Asserts access to a combined center/warehouse resource.
     * When a warehouse is supplied, warehouse visibility becomes authoritative and center scope can satisfy it.
     *
     * @param centerId center identifier
     * @param warehouseId warehouse identifier
     * @throws ForbiddenException when the current user is outside the requested scope
     */
    public void assertCenterWarehouseAccess(final Long centerId, final Long warehouseId) {
        if (warehouseId != null) {
            assertWarehouseAccess(warehouseId);
            return;
        }
        if (centerId != null) {
            assertCenterAccess(centerId);
            return;
        }
        if (!currentScopeProfile().global()) {
            throw new ForbiddenException("Access denied for unscoped resource");
        }
    }

    /**
     * Filters center identifiers to those visible to the current user.
     *
     * @param centerIds candidate center ids
     * @return in-scope center ids only
     */
    public List<Long> filterCenterIds(final Collection<Long> centerIds) {
        final ScopeAccessProfile profile = currentScopeProfile();
        return centerIds.stream().filter(profile::canAccessCenter).distinct().toList();
    }

    /**
     * Filters warehouse identifiers to those visible to the current user.
     *
     * @param warehouseIds candidate warehouse ids
     * @return in-scope warehouse ids only
     */
    public List<Long> filterWarehouseIds(final Collection<Long> warehouseIds) {
        return warehouseIds.stream().filter(this::canAccessWarehouse).distinct().toList();
    }

    /**
    /**
     * Returns whether the current user can access the supplied Warehouse.
     *
     * @param warehouseId Warehouse identifier
     * @return {@code true} when the Warehouse is visible
     */
    public boolean canAccessWarehouse(final Long warehouseId) {
        final WarehouseScope scope = loadWarehouseScopes(List.of(warehouseId)).get(warehouseId);
        return scope != null && canAccessScope(currentScopeProfile(), scope.centerId(), scope.warehouseId());
    }

    /**
     * Filters rows whose scope is derived from a Warehouse identifier.
     *
     * @param rows candidate rows
     * @param warehouseIdExtractor row-to-Warehouse mapper
     * @param <T> row type
     * @return in-scope rows only
     */
    public <T> List<T> filterByWarehouseScope(final Collection<T> rows,
                                             final Function<T, Long> warehouseIdExtractor) {
        final ScopeAccessProfile profile = currentScopeProfile();
        if (profile.global()) {
            return List.copyOf(rows);
        }

        final List<Long> warehouseIds = rows.stream()
                .map(warehouseIdExtractor)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        final Map<Long, WarehouseScope> scopes = loadWarehouseScopes(warehouseIds);

        return rows.stream()
                .filter(row -> {
                    final Long warehouseId = warehouseIdExtractor.apply(row);
                    final WarehouseScope scope = scopes.get(warehouseId);
                    return scope != null && canAccessScope(profile, scope.centerId(), scope.warehouseId());
                })
                .toList();
    }

    /**
     * Filters rows whose scope is already expressed as center/warehouse identifiers.
     *
     * @param rows candidate rows
     * @param centerIdExtractor row-to-center mapper
     * @param warehouseIdExtractor row-to-warehouse mapper
     * @param <T> row type
     * @return in-scope rows only
     */
    public <T> List<T> filterByCenterWarehouseScope(final Collection<T> rows,
                                                    final Function<T, Long> centerIdExtractor,
                                                    final Function<T, Long> warehouseIdExtractor) {
        final ScopeAccessProfile profile = currentScopeProfile();
        if (profile.global()) {
            return List.copyOf(rows);
        }

        return rows.stream()
                .filter(row -> canAccessScope(profile, centerIdExtractor.apply(row), warehouseIdExtractor.apply(row)))
                .toList();
    }

    private ScopeAccessProfile currentScopeProfile() {
        final Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof ScopedUserDetails userDetails)) {
            throw new ForbiddenException("Authentication required for scoped access");
        }
        return userDetails.getScopeAccessProfile();
    }

    private Map<Long, WarehouseScope> loadWarehouseScopes(final Collection<Long> warehouseIds) {
        if (warehouseIds.isEmpty()) {
            return Map.of();
        }

        final Map<Long, WarehouseScope> scopes = new HashMap<>();
        for (Warehouse Warehouse : WarehouseRepository.findAllById(warehouseIds)) {
            final Long warehouseId = Warehouse.getWarehouseId() == null ? null : Warehouse.getWarehouseId();
            final Long centerId = Warehouse.getWarehouseId() == null || Warehouse.getCenter() == null
                    ? null
                    : Warehouse.getCenter().getId();
            scopes.put(Warehouse.getId(), new WarehouseScope(centerId, warehouseId));
        }
        return scopes;
    }

    private boolean canAccessScope(final ScopeAccessProfile profile, final Long centerId, final Long warehouseId) {
        if (profile.global()) {
            return true;
        }
        if (warehouseId != null && profile.warehouseIds().contains(warehouseId)) {
            return true;
        }
        return centerId != null && profile.centerIds().contains(centerId);
    }

    private record WarehouseScope(Long centerId, Long warehouseId) {
    }

    public ScopeGuard(final WarehouseRepository WarehouseRepository, final WarehouseRepository warehouseRepository) {
        this.WarehouseRepository = WarehouseRepository;
        this.warehouseRepository = warehouseRepository;
    }
}
