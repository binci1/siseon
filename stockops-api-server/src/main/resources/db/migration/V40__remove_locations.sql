-- V40__remove_locations.sql
-- Remove locations table and migrate references to warehouse_id

-- 1. Add warehouse_id to inventory
ALTER TABLE inventory ADD COLUMN warehouse_id BIGINT;
UPDATE inventory i SET warehouse_id = l.warehouse_id FROM locations l WHERE i.location_id = l.id;
-- If there are any inventory records without a matched location (e.g., test data), assign them to the first available warehouse
UPDATE inventory SET warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE warehouse_id IS NULL;
ALTER TABLE inventory ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE inventory DROP CONSTRAINT IF EXISTS uk_inventory_product_location_lot;
ALTER TABLE inventory ADD CONSTRAINT uk_inventory_product_warehouse_lot UNIQUE (product_id, warehouse_id, lot_id);
ALTER TABLE inventory DROP CONSTRAINT IF EXISTS inventory_location_id_fkey;
ALTER TABLE inventory DROP COLUMN location_id;
ALTER TABLE inventory ADD CONSTRAINT inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);

-- 2. Add warehouse_id to inventory_transactions
ALTER TABLE inventory_transactions ADD COLUMN warehouse_id BIGINT;
UPDATE inventory_transactions i SET warehouse_id = l.warehouse_id FROM locations l WHERE i.location_id = l.id;
UPDATE inventory_transactions SET warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE warehouse_id IS NULL;
ALTER TABLE inventory_transactions ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS inventory_transactions_location_id_fkey;
ALTER TABLE inventory_transactions DROP COLUMN location_id;
ALTER TABLE inventory_transactions ADD CONSTRAINT inventory_transactions_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);

-- 3. Modify inventory_transfers (from_location_id, to_location_id -> from_warehouse_id, to_warehouse_id)
ALTER TABLE inventory_transfers ADD COLUMN from_warehouse_id BIGINT;
ALTER TABLE inventory_transfers ADD COLUMN to_warehouse_id BIGINT;
UPDATE inventory_transfers i SET from_warehouse_id = l.warehouse_id FROM locations l WHERE i.from_location_id = l.id;
UPDATE inventory_transfers i SET to_warehouse_id = l.warehouse_id FROM locations l WHERE i.to_location_id = l.id;
UPDATE inventory_transfers SET from_warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE from_warehouse_id IS NULL;
UPDATE inventory_transfers SET to_warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE to_warehouse_id IS NULL;
ALTER TABLE inventory_transfers ALTER COLUMN from_warehouse_id SET NOT NULL;
ALTER TABLE inventory_transfers ALTER COLUMN to_warehouse_id SET NOT NULL;
ALTER TABLE inventory_transfers DROP COLUMN from_location_id;
ALTER TABLE inventory_transfers DROP COLUMN to_location_id;

-- 4. Add warehouse_id to inbound_items
ALTER TABLE inbound_items ADD COLUMN warehouse_id BIGINT;
UPDATE inbound_items i SET warehouse_id = l.warehouse_id FROM locations l WHERE i.location_id = l.id;
UPDATE inbound_items SET warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE warehouse_id IS NULL;
ALTER TABLE inbound_items ALTER COLUMN warehouse_id SET NOT NULL;
ALTER TABLE inbound_items DROP CONSTRAINT IF EXISTS inbound_items_location_id_fkey;
ALTER TABLE inbound_items DROP COLUMN location_id;
ALTER TABLE inbound_items ADD CONSTRAINT inbound_items_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);

-- 5. Add warehouse_id to cycle_counts
ALTER TABLE cycle_counts ADD COLUMN warehouse_id BIGINT;
UPDATE cycle_counts i SET warehouse_id = l.warehouse_id FROM locations l WHERE i.location_id = l.id;
UPDATE cycle_counts SET warehouse_id = (SELECT id FROM warehouses LIMIT 1) WHERE warehouse_id IS NULL;
ALTER TABLE cycle_counts ALTER COLUMN warehouse_id SET NOT NULL;
-- cycle_counts didn't have location_id foreign key in V1, but just in case:
ALTER TABLE cycle_counts DROP COLUMN location_id;
ALTER TABLE cycle_counts ADD CONSTRAINT cycle_counts_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);

-- 6. Drop locations table
-- (All foreign keys pointing to locations are removed above)
DROP TABLE IF EXISTS locations CASCADE;
