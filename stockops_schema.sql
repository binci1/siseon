-- ============================================================
-- StockOps ?꾩껜 ?ㅽ궎留??앹꽦 ?ㅽ겕由쏀듃 (?낅┰ ?ㅽ뻾??
-- ???DB: PostgreSQL (踰꾩쟾 臾닿?)
-- ============================================================

BEGIN;

-- ============================================================
-- Source: V1__init_schema.sql
-- ============================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    barcode VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit VARCHAR(50) NOT NULL DEFAULT 'EA',
    expiry_managed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    zone VARCHAR(50),
    shelf VARCHAR(50),
    level VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE reason_codes (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE lots (
    id BIGSERIAL PRIMARY KEY,
    lot_number VARCHAR(100) NOT NULL,
    product_id BIGINT NOT NULL REFERENCES products(id),
    expiry_date DATE,
    received_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE inventory (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id),
    location_id BIGINT NOT NULL REFERENCES locations(id),
    lot_id BIGINT REFERENCES lots(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE inventory_transactions (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    product_id BIGINT NOT NULL REFERENCES products(id),
    location_id BIGINT NOT NULL REFERENCES locations(id),
    lot_id BIGINT REFERENCES lots(id),
    quantity INTEGER NOT NULL,
    before_quantity INTEGER NOT NULL,
    after_quantity INTEGER NOT NULL,
    reference_id BIGINT,
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE inbounds (
    id BIGSERIAL PRIMARY KEY,
    inbound_date DATE NOT NULL DEFAULT CURRENT_DATE,
    supplier VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    total_quantity INTEGER NOT NULL DEFAULT 0,
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE inbound_items (
    id BIGSERIAL PRIMARY KEY,
    inbound_id BIGINT NOT NULL REFERENCES inbounds(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    lot_number VARCHAR(100) NOT NULL,
    expiry_date DATE,
    quantity INTEGER NOT NULL,
    location_id BIGINT NOT NULL REFERENCES locations(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE outbounds (
    id BIGSERIAL PRIMARY KEY,
    outbound_date DATE NOT NULL DEFAULT CURRENT_DATE,
    customer VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    total_quantity INTEGER NOT NULL DEFAULT 0,
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE outbound_items (
    id BIGSERIAL PRIMARY KEY,
    outbound_id BIGINT NOT NULL REFERENCES outbounds(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    lot_id BIGINT REFERENCES lots(id),
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE stock_adjustments (
    id BIGSERIAL PRIMARY KEY,
    inventory_id BIGINT NOT NULL REFERENCES inventory(id),
    before_quantity INTEGER NOT NULL,
    after_quantity INTEGER NOT NULL,
    difference INTEGER NOT NULL,
    reason_code_id BIGINT REFERENCES reason_codes(id),
    note TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_by BIGINT REFERENCES users(id),
    approved_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(100) NOT NULL,
    entity_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    performed_by BIGINT REFERENCES users(id),
    performed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);


-- ============================================================
-- Source: V2__add_jwt_auth_schema.sql
-- ============================================================
ALTER TABLE users
    ADD COLUMN enabled BOOLEAN NOT NULL DEFAULT TRUE;

INSERT INTO roles (name, description, created_at)
SELECT 'ADMIN', 'System administrator', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM roles WHERE name = 'ADMIN'
);

INSERT INTO roles (name, description, created_at)
SELECT 'USER', 'Store operator', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM roles WHERE name = 'USER'
);

ALTER TABLE users
    ADD COLUMN role_id BIGINT;

UPDATE users
SET role_id = COALESCE(
        (SELECT id FROM roles WHERE name = users.role),
        (SELECT id FROM roles WHERE name = 'USER')
    )
WHERE role_id IS NULL;

ALTER TABLE users
    ADD CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles(id);

ALTER TABLE users
    ALTER COLUMN role_id SET NOT NULL;

ALTER TABLE users
    DROP COLUMN role;


-- ============================================================
-- Source: V3__add_inventory_status_and_constraints.sql
-- ============================================================
ALTER TABLE inventory
    ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE inventory
    ADD CONSTRAINT uk_inventory_product_location_lot UNIQUE (product_id, location_id, lot_id);


-- ============================================================
-- Source: V4__expiry_quarantine.sql
-- ============================================================
CREATE INDEX idx_lots_expiry_date ON lots(expiry_date);

CREATE INDEX idx_lots_status ON lots(status);


-- ============================================================
-- Source: V5__expiry_alerts.sql
-- ============================================================
CREATE TABLE expiry_alerts (
    id BIGSERIAL PRIMARY KEY,
    lot_id BIGINT NOT NULL REFERENCES lots(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    days_until_expiry INTEGER NOT NULL,
    alert_level VARCHAR(20) NOT NULL,
    expiry_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expiry_alerts_acknowledged ON expiry_alerts(is_acknowledged);
CREATE INDEX idx_expiry_alerts_level ON expiry_alerts(alert_level);
CREATE INDEX idx_expiry_alerts_product ON expiry_alerts(product_id);


-- ============================================================
-- Source: V6__cycle_counts.sql
-- ============================================================
CREATE TABLE cycle_counts (
    id BIGSERIAL PRIMARY KEY,
    count_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    location_id BIGINT NOT NULL REFERENCES locations(id),
    created_by BIGINT NOT NULL REFERENCES users(id),
    completed_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE cycle_count_items (
    id BIGSERIAL PRIMARY KEY,
    cycle_count_id BIGINT NOT NULL REFERENCES cycle_counts(id) ON DELETE CASCADE,
    inventory_id BIGINT NOT NULL REFERENCES inventory(id),
    expected_quantity INTEGER NOT NULL,
    actual_quantity INTEGER,
    variance INTEGER,
    counted_by BIGINT REFERENCES users(id),
    counted_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    CONSTRAINT uk_cycle_count_items_cycle_inventory UNIQUE (cycle_count_id, inventory_id)
);

CREATE INDEX idx_cycle_counts_status ON cycle_counts(status);
CREATE INDEX idx_cycle_counts_location_id ON cycle_counts(location_id);
CREATE INDEX idx_cycle_count_items_cycle_count_id ON cycle_count_items(cycle_count_id);
CREATE INDEX idx_cycle_count_items_inventory_id ON cycle_count_items(inventory_id);


-- ============================================================
-- Source: V7__centers_and_warehouses.sql
-- ============================================================
-- V7: Centers and Warehouses Schema
-- This migration adds the Center-Warehouse-Location hierarchy
-- and Purchase Order system tables

-- ============================================
-- 1. CENTERS TABLE
-- ============================================
CREATE TABLE centers (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE centers IS '동일 지역의 창고 그룹. 센터 단위 통합 재고 조회 가능';
COMMENT ON COLUMN centers.code IS '센터 고유 코드 (글로벌 유니크)';
COMMENT ON COLUMN centers.status IS 'ACTIVE, INACTIVE, CLOSED';

-- ============================================
-- 2. WAREHOUSES TABLE
-- ============================================
CREATE TABLE warehouses (
    id BIGSERIAL PRIMARY KEY,
    center_id BIGINT NOT NULL REFERENCES centers(id),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(center_id, code)
);

COMMENT ON TABLE warehouses IS '물리적 건축물. 센터에 소속되며 실제 입출고 발생 장소';
COMMENT ON COLUMN warehouses.code IS '창고 코드 (센터 내 유니크)';
COMMENT ON COLUMN warehouses.status IS 'ACTIVE, INACTIVE, CLOSED';

CREATE INDEX idx_warehouses_center_id ON warehouses(center_id);
CREATE INDEX idx_warehouses_status ON warehouses(status);

-- ============================================
-- 3. UPDATE LOCATIONS TABLE (Add warehouse_id)
-- ============================================
-- 기존 locations 테이블에 warehouse_id 컬럼 추가
ALTER TABLE locations 
    ADD COLUMN warehouse_id BIGINT REFERENCES warehouses(id);

COMMENT ON COLUMN locations.warehouse_id IS '소속 창고 ID';

CREATE INDEX idx_locations_warehouse_id ON locations(warehouse_id);

-- ============================================
-- 4. PURCHASE ORDERS TABLE
-- ============================================
CREATE TABLE purchase_orders (
    id BIGSERIAL PRIMARY KEY,
    po_number VARCHAR(100) NOT NULL UNIQUE,
    requesting_center_id BIGINT NOT NULL REFERENCES centers(id),
    target_warehouse_id BIGINT REFERENCES warehouses(id),
    supplier_name VARCHAR(255),
    supplier_code VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    erp_reference VARCHAR(255),
    requested_by BIGINT REFERENCES users(id),
    requested_at TIMESTAMP WITH TIME ZONE,
    erp_responded_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,
    total_requested_amount DECIMAL(15, 2) DEFAULT 0,
    total_accepted_amount DECIMAL(15, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE purchase_orders IS '발주 헤더. 센터에서 요청하고 창고로 입고';
COMMENT ON COLUMN purchase_orders.status IS 'DRAFT, REQUESTED, ACCEPTED, PARTIALLY_ACCEPTED, REJECTED, CANCELLED, SHIPMENT_CREATED, IN_TRANSIT, COMPLETED';

CREATE INDEX idx_purchase_orders_center_id ON purchase_orders(requesting_center_id);
CREATE INDEX idx_purchase_orders_warehouse_id ON purchase_orders(target_warehouse_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_orders_po_number ON purchase_orders(po_number);

-- ============================================
-- 5. PURCHASE ORDER ITEMS TABLE
-- ============================================
CREATE TABLE purchase_order_items (
    id BIGSERIAL PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id),
    requested_quantity INTEGER NOT NULL CHECK (requested_quantity > 0),
    accepted_quantity INTEGER DEFAULT 0 CHECK (accepted_quantity >= 0),
    cancelled_quantity INTEGER DEFAULT 0 CHECK (cancelled_quantity >= 0),
    unit_price DECIMAL(12, 2),
    total_price DECIMAL(15, 2),
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE purchase_order_items IS '발주 품목 상세';

CREATE INDEX idx_purchase_order_items_po_id ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_product_id ON purchase_order_items(product_id);

-- ============================================
-- 6. PURCHASE ORDER SHIPMENTS TABLE
-- ============================================
CREATE TABLE purchase_order_shipments (
    id BIGSERIAL PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(id),
    shipment_number VARCHAR(100) NOT NULL,
    carrier VARCHAR(100),
    tracking_number VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'CREATED',
    shipped_at TIMESTAMP WITH TIME ZONE,
    eta_date DATE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE purchase_order_shipments IS '발송 정보. 부분 발송 가능';

CREATE INDEX idx_purchase_order_shipments_po_id ON purchase_order_shipments(purchase_order_id);
CREATE INDEX idx_purchase_order_shipments_status ON purchase_order_shipments(status);

-- ============================================
-- 7. PURCHASE ORDER SHIPMENT ITEMS TABLE
-- ============================================
CREATE TABLE purchase_order_shipment_items (
    id BIGSERIAL PRIMARY KEY,
    shipment_id BIGINT NOT NULL REFERENCES purchase_order_shipments(id) ON DELETE CASCADE,
    purchase_order_item_id BIGINT NOT NULL REFERENCES purchase_order_items(id),
    shipped_quantity INTEGER NOT NULL CHECK (shipped_quantity > 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE purchase_order_shipment_items IS '발송 품목 상세';

CREATE INDEX idx_purchase_order_shipment_items_shipment_id ON purchase_order_shipment_items(shipment_id);
CREATE INDEX idx_purchase_order_shipment_items_item_id ON purchase_order_shipment_items(purchase_order_item_id);

-- ============================================
-- 8. UPDATE INBOUNDS TABLE (Add purchase_order_shipment_id)
-- ============================================
ALTER TABLE inbounds 
    ADD COLUMN purchase_order_shipment_id BIGINT REFERENCES purchase_order_shipments(id);

COMMENT ON COLUMN inbounds.purchase_order_shipment_id IS '연결된 발송 ID (발주 기반 입고)';

CREATE INDEX idx_inbounds_po_shipment_id ON inbounds(purchase_order_shipment_id);


-- ============================================================
-- Source: V8__warehouse_indexes.sql
-- ============================================================
-- V8: Warehouse query indexes
-- Adds a composite index to optimize warehouse lookups by center and status.

CREATE INDEX idx_warehouses_center_id_status ON warehouses(center_id, status);


-- ============================================================
-- Source: V9__product_fields.sql
-- ============================================================
ALTER TABLE products
    ADD COLUMN default_price DECIMAL(12,2) NOT NULL DEFAULT 0;

ALTER TABLE products
    ADD COLUMN safety_stock_quantity INTEGER NOT NULL DEFAULT 0;

UPDATE products
SET default_price = 0,
    safety_stock_quantity = 0
WHERE default_price IS NULL
   OR safety_stock_quantity IS NULL;


-- ============================================================
-- Source: V10__add_rbac_permissions_and_extended_audit.sql
-- ============================================================
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE role_permissions (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id)
);

ALTER TABLE audit_logs
    ALTER COLUMN entity_id DROP NOT NULL;

ALTER TABLE audit_logs
    ADD COLUMN target_identifier VARCHAR(255);

ALTER TABLE audit_logs
    ADD COLUMN performed_by_email VARCHAR(255);

INSERT INTO roles (name, description, created_at)
SELECT 'MANAGER', 'Operational manager', NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'MANAGER');

INSERT INTO roles (name, description, created_at)
SELECT 'STAFF', 'Operational staff', NOW()
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'STAFF');

INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
('AUDIT_LOG_READ', 'Read audit logs'),
('CENTER_CREATE', 'Create centers'),
('CENTER_DELETE', 'Delete centers'),
('CENTER_READ', 'Read centers'),
('CENTER_UPDATE', 'Update centers'),
('CYCLE_COUNT_CREATE', 'Create cycle counts'),
('CYCLE_COUNT_EXECUTE', 'Start and complete cycle counts'),
('CYCLE_COUNT_READ', 'Read cycle counts'),
('DASHBOARD_READ', 'Read dashboard data'),
('EXPIRY_ALERT_MANAGE', 'Manage expiry alerts and quarantine'),
('EXPIRY_ALERT_READ', 'Read expiry alerts'),
('INBOUND_CONFIRM', 'Confirm inbounds'),
('INBOUND_CREATE', 'Create inbounds'),
('INBOUND_READ', 'Read inbounds'),
('INVENTORY_ADJUST_APPROVE', 'Approve stock adjustments'),
('INVENTORY_ADJUST_CREATE', 'Create stock adjustments'),
('INVENTORY_ADJUST_READ', 'Read stock adjustments'),
('INVENTORY_READ', 'Read inventory'),
('LOCATION_CREATE', 'Create locations'),
('LOCATION_DELETE', 'Delete locations'),
('LOCATION_READ', 'Read locations'),
('LOCATION_UPDATE', 'Update locations'),
('OUTBOUND_CONFIRM', 'Confirm outbounds'),
('OUTBOUND_CREATE', 'Create outbounds'),
('OUTBOUND_READ', 'Read outbounds'),
('PRODUCT_CREATE', 'Create products'),
('PRODUCT_DELETE', 'Delete products'),
('PRODUCT_READ', 'Read products'),
('PRODUCT_UPDATE', 'Update products'),
('PURCHASE_ORDER_CREATE', 'Create purchase orders'),
('PURCHASE_ORDER_MANAGE', 'Manage purchase orders'),
('PURCHASE_ORDER_READ', 'Read purchase orders'),
('REASON_CODE_CREATE', 'Create reason codes'),
('REASON_CODE_DELETE', 'Delete reason codes'),
('REASON_CODE_READ', 'Read reason codes'),
('REASON_CODE_UPDATE', 'Update reason codes'),
('ROLE_CREATE', 'Create roles'),
('ROLE_DELETE', 'Delete roles'),
('ROLE_READ', 'Read roles'),
('ROLE_UPDATE', 'Update roles'),
('USER_CREATE', 'Create users'),
('USER_DELETE', 'Delete users'),
('USER_READ', 'Read users'),
('USER_UPDATE', 'Update users'),
('WAREHOUSE_CREATE', 'Create warehouses'),
('WAREHOUSE_DELETE', 'Delete warehouses'),
('WAREHOUSE_READ', 'Read warehouses'),
('WAREHOUSE_UPDATE', 'Update warehouses')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'AUDIT_LOG_READ', 'CENTER_CREATE', 'CENTER_READ', 'CENTER_UPDATE',
    'CYCLE_COUNT_CREATE', 'CYCLE_COUNT_EXECUTE', 'CYCLE_COUNT_READ',
    'DASHBOARD_READ', 'EXPIRY_ALERT_MANAGE', 'EXPIRY_ALERT_READ',
    'INBOUND_CONFIRM', 'INBOUND_CREATE', 'INBOUND_READ',
    'INVENTORY_ADJUST_APPROVE', 'INVENTORY_ADJUST_CREATE', 'INVENTORY_ADJUST_READ',
    'INVENTORY_READ', 'LOCATION_CREATE', 'LOCATION_READ', 'LOCATION_UPDATE',
    'OUTBOUND_CONFIRM', 'OUTBOUND_CREATE', 'OUTBOUND_READ',
    'PRODUCT_CREATE', 'PRODUCT_READ', 'PRODUCT_UPDATE',
    'PURCHASE_ORDER_CREATE', 'PURCHASE_ORDER_MANAGE', 'PURCHASE_ORDER_READ',
    'REASON_CODE_READ', 'ROLE_READ', 'USER_READ', 'USER_UPDATE',
    'WAREHOUSE_CREATE', 'WAREHOUSE_READ', 'WAREHOUSE_UPDATE'
)
WHERE r.name = 'MANAGER'
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'CENTER_READ', 'CYCLE_COUNT_READ', 'DASHBOARD_READ', 'EXPIRY_ALERT_READ',
    'INBOUND_CREATE', 'INBOUND_READ', 'INVENTORY_ADJUST_CREATE', 'INVENTORY_ADJUST_READ',
    'INVENTORY_READ', 'LOCATION_READ', 'OUTBOUND_CREATE', 'OUTBOUND_READ',
    'PRODUCT_READ', 'PURCHASE_ORDER_READ', 'REASON_CODE_READ', 'WAREHOUSE_READ'
)
WHERE r.name IN ('USER', 'STAFF')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);


-- ============================================================
-- Source: V11__notifications.sql
-- ============================================================
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message VARCHAR(1000) NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    event_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_notifications_user_event_key UNIQUE (user_id, event_key)
);

CREATE INDEX idx_notifications_user_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_type ON notifications(type);


-- ============================================================
-- Source: V12__product_soft_delete.sql
-- ============================================================
ALTER TABLE products
    ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE products
    DROP CONSTRAINT IF EXISTS products_barcode_key;

CREATE UNIQUE INDEX IF NOT EXISTS uk_products_barcode_active
    ON products (barcode, deleted);

CREATE INDEX IF NOT EXISTS idx_products_deleted
    ON products (deleted);


-- ============================================================
-- Source: V13__environment_monitoring.sql
-- ============================================================
-- V13: Environment Monitoring Schema
-- 센서 장치, 환경 제어기, 측정값, 알림, 제어 명령 테이블 추가

-- ============================================
-- 1. SENSOR DEVICES TABLE
-- ============================================
CREATE TABLE sensor_devices (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    sensor_type VARCHAR(100) NOT NULL,
    external_sensor_id VARCHAR(255) NOT NULL,
    mqtt_topic VARCHAR(500),
    source_channel VARCHAR(100),
    unit VARCHAR(50),
    calibration JSONB,
    noise_sigma DOUBLE PRECISION,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sensor_devices IS '환경 모니터링 센서 장치 마스터';
COMMENT ON COLUMN sensor_devices.id IS '센서 장치 PK';
COMMENT ON COLUMN sensor_devices.name IS '센서 장치 이름';
COMMENT ON COLUMN sensor_devices.location IS '센서가 설치된 위치 설명';
COMMENT ON COLUMN sensor_devices.sensor_type IS '센서 유형 코드 (예: TEMPERATURE, HUMIDITY)';
COMMENT ON COLUMN sensor_devices.external_sensor_id IS '외부 시스템에서 사용하는 센서 식별자';
COMMENT ON COLUMN sensor_devices.mqtt_topic IS '센서 데이터 수신 MQTT 토픽';
COMMENT ON COLUMN sensor_devices.source_channel IS '센서 원본 채널 또는 포트 정보';
COMMENT ON COLUMN sensor_devices.unit IS '센서 기본 측정 단위';
COMMENT ON COLUMN sensor_devices.calibration IS '보정 파라미터 JSON';
COMMENT ON COLUMN sensor_devices.noise_sigma IS '센서 노이즈 표준편차';
COMMENT ON COLUMN sensor_devices.deleted IS '소프트 삭제 여부';
COMMENT ON COLUMN sensor_devices.active IS '재활성화 가능 여부를 포함한 현재 사용 상태';
COMMENT ON COLUMN sensor_devices.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN sensor_devices.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE UNIQUE INDEX IF NOT EXISTS uk_sensor_devices_external_sensor_id_active
    ON sensor_devices (external_sensor_id, deleted);

CREATE INDEX IF NOT EXISTS idx_sensor_devices_deleted
    ON sensor_devices (deleted);

-- ============================================
-- 2. ENVIRONMENT CONTROLLERS TABLE
-- ============================================
CREATE TABLE environment_controllers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    external_controller_id VARCHAR(255) NOT NULL,
    controller_type VARCHAR(50) NOT NULL DEFAULT 'ventilation',
    target_axis VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'INACTIVE',
    output_level INTEGER NOT NULL DEFAULT 0 CHECK (output_level >= 0 AND output_level <= 100),
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (controller_type IN ('cooling', 'heating', 'humidifying', 'dehumidifying', 'ventilation', 'air_purifier'))
);

COMMENT ON TABLE environment_controllers IS '환경 제어 장치 마스터';
COMMENT ON COLUMN environment_controllers.id IS '환경 제어 장치 PK';
COMMENT ON COLUMN environment_controllers.name IS '제어 장치 이름';
COMMENT ON COLUMN environment_controllers.external_controller_id IS '외부 시스템에서 사용하는 제어기 식별자';
COMMENT ON COLUMN environment_controllers.controller_type IS '제어기 유형 (cooling/heating/humidifying/dehumidifying/ventilation/air_purifier)';
COMMENT ON COLUMN environment_controllers.target_axis IS '제어 대상 축 (예: temperature, humidity, air_quality)';
COMMENT ON COLUMN environment_controllers.status IS '제어기 현재 상태 (INACTIVE, READY, RUNNING, ERROR 등)';
COMMENT ON COLUMN environment_controllers.output_level IS '현재 출력 레벨 (0-100)';
COMMENT ON COLUMN environment_controllers.deleted IS '소프트 삭제 여부';
COMMENT ON COLUMN environment_controllers.active IS '재활성화 가능 여부를 포함한 현재 사용 상태';
COMMENT ON COLUMN environment_controllers.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN environment_controllers.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE UNIQUE INDEX IF NOT EXISTS uk_environment_controllers_external_controller_id_active
    ON environment_controllers (external_controller_id, deleted);

CREATE INDEX IF NOT EXISTS idx_environment_controllers_deleted
    ON environment_controllers (deleted);

-- ============================================
-- 3. SENSOR READINGS TABLE
-- ============================================
CREATE TABLE sensor_readings (
    id BIGSERIAL PRIMARY KEY,
    sensor_device_id BIGINT NOT NULL REFERENCES sensor_devices(id),
    value DOUBLE PRECISION NOT NULL,
    value_kind VARCHAR(50) NOT NULL,
    unit VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sequence_id BIGINT,
    raw_payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sensor_readings IS '센서 측정 이력 데이터';
COMMENT ON COLUMN sensor_readings.id IS '센서 측정 이력 PK';
COMMENT ON COLUMN sensor_readings.sensor_device_id IS '측정값을 생성한 센서 장치 ID';
COMMENT ON COLUMN sensor_readings.value IS '측정값';
COMMENT ON COLUMN sensor_readings.value_kind IS '측정값 종류 (예: raw, averaged, compensated)';
COMMENT ON COLUMN sensor_readings.unit IS '측정 단위';
COMMENT ON COLUMN sensor_readings.status IS '측정 상태 (NORMAL, WARN, ERROR 등)';
COMMENT ON COLUMN sensor_readings.recorded_at IS '센서가 측정한 시각 (UTC 기준 저장)';
COMMENT ON COLUMN sensor_readings.sequence_id IS '외부 페이로드 순번';
COMMENT ON COLUMN sensor_readings.raw_payload IS '원본 센서 페이로드 JSON';
COMMENT ON COLUMN sensor_readings.created_at IS '레코드 생성 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at
    ON sensor_readings (recorded_at);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_sensor_device_recorded_at
    ON sensor_readings (sensor_device_id, recorded_at);

-- ============================================
-- 3.1 SENSOR LATEST PROJECTION TABLE
-- ============================================
CREATE TABLE sensor_latest (
    sensor_device_id BIGINT PRIMARY KEY REFERENCES sensor_devices(id),
    value DOUBLE PRECISION,
    value_kind VARCHAR(50),
    unit VARCHAR(50),
    status VARCHAR(30),
    recorded_at TIMESTAMP WITH TIME ZONE,
    sequence_id BIGINT,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sensor_latest IS '센서 최신 상태 프로젝션';
COMMENT ON COLUMN sensor_latest.sensor_device_id IS '센서 장치 ID (PK/FK)';
COMMENT ON COLUMN sensor_latest.value IS '최신 측정값';
COMMENT ON COLUMN sensor_latest.value_kind IS '최신 측정값 종류';
COMMENT ON COLUMN sensor_latest.unit IS '최신 측정 단위';
COMMENT ON COLUMN sensor_latest.status IS '최신 측정 상태';
COMMENT ON COLUMN sensor_latest.recorded_at IS '최신 센서 측정 시각 (UTC 기준 저장)';
COMMENT ON COLUMN sensor_latest.sequence_id IS '최신 외부 페이로드 순번';
COMMENT ON COLUMN sensor_latest.updated_at IS '프로젝션 갱신 시각 (UTC 기준 저장)';

-- ============================================
-- 4. ENVIRONMENT ALERTS TABLE
-- ============================================
CREATE TABLE environment_alerts (
    id BIGSERIAL PRIMARY KEY,
    sensor_device_id BIGINT REFERENCES sensor_devices(id),
    alert_type VARCHAR(100) NOT NULL,
    severity VARCHAR(30) NOT NULL DEFAULT 'INFO',
    message TEXT NOT NULL,
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE environment_alerts IS '환경 이상 감지 및 운영 알림';
COMMENT ON COLUMN environment_alerts.id IS '환경 알림 PK';
COMMENT ON COLUMN environment_alerts.sensor_device_id IS '관련 센서 장치 ID (시스템 알림은 NULL 가능)';
COMMENT ON COLUMN environment_alerts.alert_type IS '알림 유형 코드';
COMMENT ON COLUMN environment_alerts.severity IS '알림 심각도 (INFO, WARNING, CRITICAL 등)';
COMMENT ON COLUMN environment_alerts.message IS '알림 메시지 본문';
COMMENT ON COLUMN environment_alerts.acknowledged IS '알림 확인 여부';
COMMENT ON COLUMN environment_alerts.acknowledged_at IS '알림 확인 시각 (UTC 기준 저장)';
COMMENT ON COLUMN environment_alerts.acknowledged_by IS '알림 확인자';
COMMENT ON COLUMN environment_alerts.created_at IS '알림 생성 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_environment_alerts_created_at
    ON environment_alerts (created_at);

CREATE INDEX IF NOT EXISTS idx_environment_alerts_sensor_device_id
    ON environment_alerts (sensor_device_id);

-- ============================================
-- 5. CONTROLLER COMMANDS TABLE
-- ============================================
CREATE TABLE controller_commands (
    id BIGSERIAL PRIMARY KEY,
    controller_id BIGINT NOT NULL REFERENCES environment_controllers(id),
    requested_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    requested_output_level INTEGER CHECK (requested_output_level >= 0 AND requested_output_level <= 100),
    result_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    result_message TEXT,
    sensimul_response_code VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (result_status IN ('PENDING', 'FORWARDED', 'APPLIED', 'FAILED_RETRYABLE'))
);

COMMENT ON TABLE controller_commands IS '환경 제어기 제어 명령 이력';
COMMENT ON COLUMN controller_commands.id IS '제어 명령 이력 PK';
COMMENT ON COLUMN controller_commands.controller_id IS '명령 대상 제어기 ID';
COMMENT ON COLUMN controller_commands.requested_status IS '요청한 제어 상태';
COMMENT ON COLUMN controller_commands.requested_output_level IS '요청한 출력 레벨 (0-100)';
COMMENT ON COLUMN controller_commands.result_status IS '명령 처리 결과 상태 (PENDING, FORWARDED, SUCCESS, FAILED_RETRYABLE)';
COMMENT ON COLUMN controller_commands.result_message IS '명령 처리 결과 메시지';
COMMENT ON COLUMN controller_commands.sensimul_response_code IS 'Sensimul 응답 코드';
COMMENT ON COLUMN controller_commands.created_at IS '명령 생성 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_controller_commands_controller_id_created_at
    ON controller_commands (controller_id, created_at);


-- ============================================================
-- Source: V14__environment_permissions.sql
-- ============================================================
-- V14: Environment Monitoring Permissions
-- 환경 모니터링 관련 권한 추가 및 역할 할당

-- ============================================
-- 1. ENVIRONMENT PERMISSIONS
-- ============================================
INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
('ENVIRONMENT_READ', 'Read environment monitoring data (sensors, controllers, dashboard, alerts, history)'),
('ENVIRONMENT_MANAGE', 'Manage environment sensors and controllers (create, update, delete)'),
('ENVIRONMENT_COMMAND', 'Send commands to environment controllers')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

-- ============================================
-- 2. ADMIN ROLE GETS ALL ENVIRONMENT PERMISSIONS
-- ============================================
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
  AND p.code IN ('ENVIRONMENT_READ', 'ENVIRONMENT_MANAGE', 'ENVIRONMENT_COMMAND')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

-- ============================================
-- 3. MANAGER ROLE GETS READ + MANAGE + COMMAND
-- ============================================
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'ENVIRONMENT_READ',
    'ENVIRONMENT_MANAGE',
    'ENVIRONMENT_COMMAND'
)
WHERE r.name = 'MANAGER'
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

-- ============================================
-- 4. USER/STAFF ROLE GETS READ ONLY
-- ============================================
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN ('ENVIRONMENT_READ')
WHERE r.name IN ('USER', 'STAFF')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);


-- ============================================================
-- Source: V15__fix_environment_alerts_updated_at.sql
-- ============================================================
-- V15: Add missing updated_at column to environment_alerts
-- BaseEntity requires updated_at but V13 migration didn't include it

ALTER TABLE environment_alerts
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;


-- ============================================================
-- Source: V16__ensure_admin_all_permissions.sql
-- ============================================================
-- V16: Ensure ADMIN role has all permissions including ENVIRONMENT_*
-- This migration ensures ADMIN always has all permissions regardless of when they were added
-- Uses a simpler approach without CROSS JOIN to avoid any timing issues

-- 1. First ensure ADMIN has all permissions that exist at migration time
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

-- 2. Verify ENVIRONMENT_* permissions exist, insert if not
INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
('ENVIRONMENT_READ', 'Read environment monitoring data'),
('ENVIRONMENT_MANAGE', 'Manage environment sensors and controllers'),
('ENVIRONMENT_COMMAND', 'Send commands to environment controllers')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

-- 3. Now assign ENVIRONMENT_* to ADMIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
  AND p.code IN ('ENVIRONMENT_READ', 'ENVIRONMENT_MANAGE', 'ENVIRONMENT_COMMAND')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

-- 4. Also grant all permissions to MANAGER role for environment
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'MANAGER'
  AND p.code IN ('ENVIRONMENT_READ', 'ENVIRONMENT_MANAGE', 'ENVIRONMENT_COMMAND')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);


-- ============================================================
-- Source: V17__fix_environment_schema.sql
-- ============================================================
-- V17: Fix environment monitoring schema issues
-- 1. Add updated_at to sensor_readings (required by BaseEntity)
-- 2. Make value_kind nullable (Sensimul can send null valueKind)
-- 3. Fix controller_type to use uppercase enum values
-- 4. Add updated_at to controller_commands (required by BaseEntity)

-- 1. Add updated_at column to sensor_readings
ALTER TABLE sensor_readings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 2. Make value_kind nullable for Sensimul compatibility
ALTER TABLE sensor_readings ALTER COLUMN value_kind DROP NOT NULL;

-- 3. Fix controller_type enum values (change from lowercase to uppercase)
ALTER TABLE environment_controllers DROP CONSTRAINT IF EXISTS environment_controllers_controller_type_check;
ALTER TABLE environment_controllers ADD CONSTRAINT environment_controllers_controller_type_check
  CHECK (controller_type IN ('COOLING', 'HEATING', 'HUMIDIFYING', 'DEHUMIDIFYING', 'VENTILATION', 'AIR_PURIFIER'));

UPDATE environment_controllers SET controller_type = 'AIR_PURIFIER' WHERE controller_type = 'air_purifier';
UPDATE environment_controllers SET controller_type = 'COOLING' WHERE controller_type = 'cooling';
UPDATE environment_controllers SET controller_type = 'HEATING' WHERE controller_type = 'heating';
UPDATE environment_controllers SET controller_type = 'HUMIDIFYING' WHERE controller_type = 'humidifying';
UPDATE environment_controllers SET controller_type = 'DEHUMIDIFYING' WHERE controller_type = 'dehumidifying';
UPDATE environment_controllers SET controller_type = 'VENTILATION' WHERE controller_type = 'ventilation';

-- 4. Add updated_at column to controller_commands
ALTER TABLE controller_commands ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;


-- ============================================================
-- Source: V18__add_controller_mqtt_topic.sql
-- ============================================================
-- V18: Add mqtt_topic to environment_controllers
ALTER TABLE environment_controllers ADD COLUMN IF NOT EXISTS mqtt_topic VARCHAR(500);

UPDATE environment_controllers SET mqtt_topic = 'sensimul/sites/849dc38d-cb7a-42a5-9d4e-adaf1e5bc4cc/controllers/' || external_controller_id WHERE external_controller_id = 'ctrl-849dc38d';
UPDATE environment_controllers SET mqtt_topic = 'sensimul/sites/1eaf59ad-958a-493e-b6b7-fc86c7d5eda1/controllers/' || external_controller_id WHERE external_controller_id = 'ctrl-1eaf59ad';

COMMENT ON COLUMN environment_controllers.mqtt_topic IS '제어기 MQTT 토픽 (sensimul/sites/{siteId}/controllers/{controllerId})';


-- ============================================================
-- Source: V19__add_scope_assignments.sql
-- ============================================================
CREATE TABLE role_scope_assignments (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    scope_type VARCHAR(20) NOT NULL,
    center_id BIGINT REFERENCES centers(id),
    warehouse_id BIGINT REFERENCES warehouses(id),
    CONSTRAINT chk_role_scope_assignment_type CHECK (
        (scope_type = 'GLOBAL' AND center_id IS NULL AND warehouse_id IS NULL)
            OR (scope_type = 'CENTER' AND center_id IS NOT NULL AND warehouse_id IS NULL)
            OR (scope_type = 'WAREHOUSE' AND warehouse_id IS NOT NULL)
        )
);

CREATE INDEX idx_role_scope_assignments_center_id ON role_scope_assignments(center_id);
CREATE INDEX idx_role_scope_assignments_warehouse_id ON role_scope_assignments(warehouse_id);

CREATE TABLE user_scope_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scope_type VARCHAR(20) NOT NULL,
    center_id BIGINT REFERENCES centers(id),
    warehouse_id BIGINT REFERENCES warehouses(id),
    CONSTRAINT chk_user_scope_assignment_type CHECK (
        (scope_type = 'GLOBAL' AND center_id IS NULL AND warehouse_id IS NULL)
            OR (scope_type = 'CENTER' AND center_id IS NOT NULL AND warehouse_id IS NULL)
            OR (scope_type = 'WAREHOUSE' AND warehouse_id IS NOT NULL)
        )
);

CREATE INDEX idx_user_scope_assignments_center_id ON user_scope_assignments(center_id);
CREATE INDEX idx_user_scope_assignments_warehouse_id ON user_scope_assignments(warehouse_id);


-- ============================================================
-- Source: V20__ai_recommendation_engine.sql
-- ============================================================
CREATE SCHEMA IF NOT EXISTS analytics;

INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
('AI_RECOMMENDATION_READ', 'Read deterministic AI reorder recommendations'),
('AI_RECOMMENDATION_APPROVE', 'Approve AI reorder recommendations into draft purchase orders')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN ('AI_RECOMMENDATION_READ', 'AI_RECOMMENDATION_APPROVE')
WHERE r.name IN ('ADMIN', 'MANAGER')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN ('AI_RECOMMENDATION_READ')
WHERE r.name IN ('USER', 'STAFF')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

CREATE TABLE analytics.ai_forecast_snapshots (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    forecast_start_date DATE NOT NULL,
    forecast_end_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    trailing_seven_day_average NUMERIC(12, 2) NOT NULL DEFAULT 0,
    same_weekday_average NUMERIC(12, 2) NOT NULL DEFAULT 0,
    weighted_daily_demand NUMERIC(12, 2) NOT NULL DEFAULT 0,
    seven_day_forecast_quantity INTEGER NOT NULL DEFAULT 0,
    lead_time_days INTEGER NOT NULL DEFAULT 1,
    lead_time_demand_quantity INTEGER NOT NULL DEFAULT 0,
    history_days_considered INTEGER NOT NULL DEFAULT 0,
    demand_event_count INTEGER NOT NULL DEFAULT 0,
    insufficient_history BOOLEAN NOT NULL DEFAULT FALSE,
    explanation_summary VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_ai_forecast_snapshot_scope_date UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_ai_forecast_snapshot_lookup
    ON analytics.ai_forecast_snapshots (business_date, center_id, warehouse_id, product_id);

CREATE TABLE analytics.ai_reorder_recommendations (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    forecast_snapshot_id BIGINT NOT NULL REFERENCES analytics.ai_forecast_snapshots(id) ON DELETE CASCADE,
    current_stock_quantity INTEGER NOT NULL DEFAULT 0,
    safety_stock_quantity INTEGER NOT NULL DEFAULT 0,
    recommended_quantity INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL,
    explanation_summary VARCHAR(500),
    approved_purchase_order_id BIGINT REFERENCES public.purchase_orders(id),
    approved_by_user_id BIGINT REFERENCES public.users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_ai_recommendation_scope_date UNIQUE (business_date, product_id, center_id, warehouse_id),
    CONSTRAINT uk_ai_recommendation_forecast UNIQUE (forecast_snapshot_id)
);

CREATE INDEX idx_ai_recommendation_lookup
    ON analytics.ai_reorder_recommendations (business_date, center_id, warehouse_id, product_id, status);


-- ============================================================
-- Source: V21__analytics_read_model.sql
-- ============================================================
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE analytics.daily_demand_history (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    confirmed_outbound_quantity INTEGER NOT NULL DEFAULT 0,
    confirmed_outbound_event_count INTEGER NOT NULL DEFAULT 0,
    insufficient_history BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_analytics_daily_demand UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_analytics_daily_demand_lookup
    ON analytics.daily_demand_history (business_date, center_id, warehouse_id, product_id);

CREATE TABLE analytics.daily_stock_position (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    on_hand_quantity INTEGER NOT NULL DEFAULT 0,
    available_quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    quarantined_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_analytics_daily_stock UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_analytics_daily_stock_lookup
    ON analytics.daily_stock_position (business_date, center_id, warehouse_id, product_id);

CREATE TABLE analytics.daily_expiry_waste (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    quarantined_quantity INTEGER NOT NULL DEFAULT 0,
    quarantined_lot_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_analytics_daily_expiry_waste UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_analytics_daily_expiry_waste_lookup
    ON analytics.daily_expiry_waste (business_date, center_id, warehouse_id, product_id);

CREATE TABLE analytics.daily_purchase_order_lead_time (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    purchase_order_count INTEGER NOT NULL DEFAULT 0,
    lead_time_sample_count INTEGER NOT NULL DEFAULT 0,
    total_lead_time_hours BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_analytics_daily_po_lead_time UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_analytics_daily_po_lead_time_lookup
    ON analytics.daily_purchase_order_lead_time (business_date, center_id, warehouse_id, product_id);

CREATE TABLE analytics.daily_fill_rate_source (
    id BIGSERIAL PRIMARY KEY,
    business_date DATE NOT NULL,
    product_id BIGINT NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    purchase_order_count INTEGER NOT NULL DEFAULT 0,
    requested_quantity INTEGER NOT NULL DEFAULT 0,
    accepted_quantity INTEGER NOT NULL DEFAULT 0,
    cancelled_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_analytics_daily_fill_rate_source UNIQUE (business_date, product_id, center_id, warehouse_id)
);

CREATE INDEX idx_analytics_daily_fill_rate_source_lookup
    ON analytics.daily_fill_rate_source (business_date, center_id, warehouse_id, product_id);


-- ============================================================
-- Source: V22__notices_table.sql
-- ============================================================
-- Notices table for admin announcements
CREATE TABLE notices (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    type VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    active BOOLEAN NOT NULL DEFAULT true,
    created_by BIGINT,
    notice_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT false,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_notices_created_by FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_notices_active ON notices(active);
CREATE INDEX idx_notices_type ON notices(type);
CREATE INDEX idx_notices_notice_at ON notices(notice_at);

-- ============================================================
-- Source: V23__demand_forecasts_table.sql
-- ============================================================
-- Demand forecasts table for ML predictions
CREATE TABLE demand_forecasts (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    forecast_date DATE NOT NULL,
    predicted_quantity DECIMAL(15,3) NOT NULL,
    confidence_lower DECIMAL(15,3),
    confidence_upper DECIMAL(15,3),
    model_version VARCHAR(50) DEFAULT 'v1.0',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT false,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_demand_forecasts_product FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE INDEX idx_demand_forecasts_product_date ON demand_forecasts(product_id, forecast_date);
CREATE INDEX idx_demand_forecasts_date ON demand_forecasts(forecast_date);

-- ============================================================
-- Source: V24__add_inventory_transfers.sql
-- ============================================================
-- Inventory transfers table for atomic stock movement between locations
CREATE TABLE inventory_transfers (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    lot_id BIGINT,
    from_location_id BIGINT NOT NULL,
    to_location_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'REQUESTED',
    requested_by BIGINT REFERENCES users(id),
    completed_by BIGINT REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_transfers_status ON inventory_transfers(status);
CREATE INDEX idx_inventory_transfers_from_location ON inventory_transfers(from_location_id);
CREATE INDEX idx_inventory_transfers_to_location ON inventory_transfers(to_location_id);
CREATE INDEX idx_inventory_transfers_product ON inventory_transfers(product_id);


-- ============================================================
-- Source: V25__add_warehouse_closure_columns.sql
-- ============================================================
-- V25: Add warehouse closure tracking columns
ALTER TABLE warehouses
    ADD COLUMN closure_reason TEXT;

ALTER TABLE warehouses
    ADD COLUMN closed_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN warehouses.closure_reason IS '창고 폐쇄 사유';
COMMENT ON COLUMN warehouses.closed_at IS '창고 폐쇄 일시';


-- ============================================================
-- Source: V26__add_forecast_model_version.sql
-- ============================================================
ALTER TABLE analytics.ai_forecast_snapshots
    ADD COLUMN IF NOT EXISTS model_version VARCHAR(50) NOT NULL DEFAULT 'statistical';


-- ============================================================
-- Source: V27__add_escalation_policy.sql
-- ============================================================
-- V27: Escalation Policy Schema
-- 에스컬레이션 정책 및 규칙 테이블 추가
-- 환경 모니터링 알림의 다단계 에스컬레이션 지원

-- ============================================
-- 1. ESCALATION POLICIES TABLE
-- ============================================
CREATE TABLE escalation_policies (
    id BIGSERIAL PRIMARY KEY,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT,
    alert_type VARCHAR(50) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_escalation_policies_center FOREIGN KEY (center_id) REFERENCES centers(id),
    CONSTRAINT fk_escalation_policies_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);

COMMENT ON TABLE escalation_policies IS '에스컬레이션 정책 마스터 - 센터/창고 및 알림 유형별 에스컬레이션 규칙 그룹';
COMMENT ON COLUMN escalation_policies.id IS '에스컬레이션 정책 PK';
COMMENT ON COLUMN escalation_policies.center_id IS '센터 ID (필수)';
COMMENT ON COLUMN escalation_policies.warehouse_id IS '창고 ID (NULL이면 센터 전체 정책)';
COMMENT ON COLUMN escalation_policies.alert_type IS '알림 유형 (TEMPERATURE, HUMIDITY, AIR_QUALITY 등)';
COMMENT ON COLUMN escalation_policies.active IS '정책 활성 여부';
COMMENT ON COLUMN escalation_policies.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN escalation_policies.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_escalation_policies_center_id
    ON escalation_policies (center_id);

CREATE INDEX IF NOT EXISTS idx_escalation_policies_warehouse_id
    ON escalation_policies (warehouse_id);

CREATE UNIQUE INDEX IF NOT EXISTS uk_escalation_policies_scope
    ON escalation_policies (center_id, warehouse_id, alert_type, active);

-- ============================================
-- 2. ESCALATION RULES TABLE
-- ============================================
CREATE TABLE escalation_rules (
    id BIGSERIAL PRIMARY KEY,
    policy_id BIGINT NOT NULL REFERENCES escalation_policies(id) ON DELETE CASCADE,
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 3),
    delay_minutes INTEGER NOT NULL DEFAULT 0,
    notify_roles JSONB NOT NULL DEFAULT '[]',
    channels JSONB NOT NULL DEFAULT '["EMAIL"]',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_escalation_rules_policy_level UNIQUE (policy_id, level)
);

COMMENT ON TABLE escalation_rules IS '에스컬레이션 규칙 - 정책별 다단계 알림 규칙';
COMMENT ON COLUMN escalation_rules.id IS '에스컬레이션 규칙 PK';
COMMENT ON COLUMN escalation_rules.policy_id IS '소속 정책 ID';
COMMENT ON COLUMN escalation_rules.level IS '에스컬레이션 레벨 (1-3)';
COMMENT ON COLUMN escalation_rules.delay_minutes IS '이전 레벨 이후 대기 시간 (분)';
COMMENT ON COLUMN escalation_rules.notify_roles IS '알림 대상 역할 JSON 배열 (예: ["ROLE_CENTER_MANAGER"])';
COMMENT ON COLUMN escalation_rules.channels IS '알림 채널 JSON 배열 (예: ["EMAIL", "SMS"])';
COMMENT ON COLUMN escalation_rules.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN escalation_rules.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_escalation_rules_policy_id
    ON escalation_rules (policy_id);


-- ============================================================
-- Source: V28__add_pending_alert.sql
-- ============================================================
-- V28: Pending Alerts and User Phone
-- 대기 중인 환경 알림 추적 및 사용자 전화번호 추가
-- 에스컬레이션 스케줄러가 DB에서 PENDING 알림을 조회하여 자동 에스컬레이션

-- ============================================
-- 1. PENDING_ALERTS TABLE
-- ============================================
CREATE TABLE pending_alerts (
    id BIGSERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    center_id BIGINT NOT NULL,
    warehouse_id BIGINT,
    sensor_id BIGINT,
    message TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    current_level INTEGER NOT NULL DEFAULT 0,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pending_alerts_center FOREIGN KEY (center_id) REFERENCES centers(id),
    CONSTRAINT fk_pending_alerts_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
);

COMMENT ON TABLE pending_alerts IS '대기 중인 환경 알림 - 에스컬레이션 대기/진행/확인 상태 추적';
COMMENT ON COLUMN pending_alerts.id IS '대기 알림 PK';
COMMENT ON COLUMN pending_alerts.alert_type IS '알림 유형 (TEMPERATURE, HUMIDITY, AIR_QUALITY 등)';
COMMENT ON COLUMN pending_alerts.center_id IS '센터 ID (필수)';
COMMENT ON COLUMN pending_alerts.warehouse_id IS '창고 ID (NULL이면 센터 전체 알림)';
COMMENT ON COLUMN pending_alerts.sensor_id IS '센서 ID (NULL 가능)';
COMMENT ON COLUMN pending_alerts.message IS '알림 메시지';
COMMENT ON COLUMN pending_alerts.severity IS '심각도 (WARNING, CRITICAL 등)';
COMMENT ON COLUMN pending_alerts.status IS '상태 (PENDING, ESCALATED, ACKNOWLEDGED)';
COMMENT ON COLUMN pending_alerts.current_level IS '현재 에스컬레이션 레벨 (0=초기)';
COMMENT ON COLUMN pending_alerts.acknowledged_at IS '확인 시각 (UTC)';
COMMENT ON COLUMN pending_alerts.acknowledged_by IS '확인자 사용자명';
COMMENT ON COLUMN pending_alerts.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN pending_alerts.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_pending_alerts_status
    ON pending_alerts (status);

CREATE INDEX IF NOT EXISTS idx_pending_alerts_status_created
    ON pending_alerts (status, created_at);

-- ============================================
-- 2. ADD PHONE COLUMN TO USERS TABLE
-- ============================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50);

COMMENT ON COLUMN users.phone IS '사용자 전화번호 (E.164 형식, SMS 알림용)';

-- ============================================================
-- Source: V29__add_category.sql
-- ============================================================
-- V29: Category hierarchy for product classification
-- Self-referencing 3-level category (대분류 → 중분류 → 소분류)

-- ============================================
-- 1. CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    parent_id BIGINT,
    level INTEGER NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_id) REFERENCES categories(id)
);

COMMENT ON TABLE categories IS '상품 분류 계층 - 3단계 분류 (대분류/중분류/소분류)';
COMMENT ON COLUMN categories.id IS '카테고리 PK';
COMMENT ON COLUMN categories.name IS '카테고리 이름';
COMMENT ON COLUMN categories.code IS '카테고리 코드 (고유)';
COMMENT ON COLUMN categories.parent_id IS '상위 카테고리 ID (NULL이면 최상위)';
COMMENT ON COLUMN categories.level IS '레벨 (1=대분류, 2=중분류, 3=소분류)';
COMMENT ON COLUMN categories.sort_order IS '정렬 순서';
COMMENT ON COLUMN categories.active IS '활성 상태';
COMMENT ON COLUMN categories.created_at IS '생성 시각 (UTC)';
COMMENT ON COLUMN categories.updated_at IS '수정 시각 (UTC)';

CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories (parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories (level);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories (active);
CREATE INDEX IF NOT EXISTS idx_categories_code ON categories (code);

-- ============================================
-- 2. ADD CATEGORY_ID TO PRODUCTS
-- ============================================
ALTER TABLE products ADD COLUMN IF NOT EXISTS category_id BIGINT;

COMMENT ON COLUMN products.category_id IS '상품 카테고리 FK (nullable - 기존 상품은 카테고리 없음)';

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id);

-- ============================================
-- 3. SEED DATA - 3 LEVELS OF CATEGORIES
-- ============================================
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    -- Level 1: 대분류 (Root categories)
    ('식품', 'FOOD', NULL, 1, 1, true),
    ('화장품', 'COSMETIC', NULL, 1, 2, true),
    ('생활용품', 'HOUSEHOLD', NULL, 1, 3, true);

-- Level 2: 중분류 (Children of FOOD)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('과자', 'FOOD_SNACK', (SELECT id FROM categories WHERE code = 'FOOD'), 2, 1, true),
    ('음료', 'FOOD_DRINK', (SELECT id FROM categories WHERE code = 'FOOD'), 2, 2, true),
    ('편의식', 'FOOD_CONVENIENCE', (SELECT id FROM categories WHERE code = 'FOOD'), 2, 3, true);

-- Level 2: 중분류 (Children of COSMETIC)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('스킨케어', 'COSMETIC_SKIN', (SELECT id FROM categories WHERE code = 'COSMETIC'), 2, 1, true),
    ('메이크업', 'COSMETIC_MAKEUP', (SELECT id FROM categories WHERE code = 'COSMETIC'), 2, 2, true),
    ('헤어케어', 'COSMETIC_HAIR', (SELECT id FROM categories WHERE code = 'COSMETIC'), 2, 3, true);

-- Level 2: 중분류 (Children of HOUSEHOLD)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('세제', 'HOUSEHOLD_DETERGENT', (SELECT id FROM categories WHERE code = 'HOUSEHOLD'), 2, 1, true),
    ('청소용품', 'HOUSEHOLD_CLEANING', (SELECT id FROM categories WHERE code = 'HOUSEHOLD'), 2, 2, true),
    ('생활잡화', 'HOUSEHOLD_MISC', (SELECT id FROM categories WHERE code = 'HOUSEHOLD'), 2, 3, true);

-- Level 3: 소분류 (Children of FOOD_SNACK)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('스낵', 'FOOD_SNACK_SNACK', (SELECT id FROM categories WHERE code = 'FOOD_SNACK'), 3, 1, true),
    ('초콜릿', 'FOOD_SNACK_CHOCOLATE', (SELECT id FROM categories WHERE code = 'FOOD_SNACK'), 3, 2, true),
    ('캔디', 'FOOD_SNACK_CANDY', (SELECT id FROM categories WHERE code = 'FOOD_SNACK'), 3, 3, true);

-- Level 3: 소분류 (Children of FOOD_DRINK)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('탄산음료', 'FOOD_DRINK_SODA', (SELECT id FROM categories WHERE code = 'FOOD_DRINK'), 3, 1, true),
    ('주스', 'FOOD_DRINK_JUICE', (SELECT id FROM categories WHERE code = 'FOOD_DRINK'), 3, 2, true),
    ('생수', 'FOOD_DRINK_WATER', (SELECT id FROM categories WHERE code = 'FOOD_DRINK'), 3, 3, true),
    ('커피', 'FOOD_DRINK_COFFEE', (SELECT id FROM categories WHERE code = 'FOOD_DRINK'), 3, 4, true);

-- Level 3: 소분류 (Children of COSMETIC_SKIN)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('토너', 'COSMETIC_SKIN_TONER', (SELECT id FROM categories WHERE code = 'COSMETIC_SKIN'), 3, 1, true),
    ('에센스', 'COSMETIC_SKIN_ESSENCE', (SELECT id FROM categories WHERE code = 'COSMETIC_SKIN'), 3, 2, true),
    ('크림', 'COSMETIC_SKIN_CREAM', (SELECT id FROM categories WHERE code = 'COSMETIC_SKIN'), 3, 3, true),
    ('마스크', 'COSMETIC_SKIN_MASK', (SELECT id FROM categories WHERE code = 'COSMETIC_SKIN'), 3, 4, true);

-- Level 3: 소분류 (Children of HOUSEHOLD_DETERGENT)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('세탁세제', 'HOUSEHOLD_DETERGENT_LAUNDRY', (SELECT id FROM categories WHERE code = 'HOUSEHOLD_DETERGENT'), 3, 1, true),
    ('주방세제', 'HOUSEHOLD_DETERGENT_KITCHEN', (SELECT id FROM categories WHERE code = 'HOUSEHOLD_DETERGENT'), 3, 2, true),
    ('샴푸', 'HOUSEHOLD_DETERGENT_SHAMPOO', (SELECT id FROM categories WHERE code = 'HOUSEHOLD_DETERGENT'), 3, 3, true);

-- ============================================================
-- Source: V30__webhook_endpoint_config.sql
-- ============================================================
-- V30: Webhook endpoint configuration table
-- Stores per-center/warehouse webhook endpoints with provider type and extra config

CREATE TABLE webhook_endpoint_config (
    id              BIGSERIAL       PRIMARY KEY,
    center_id       BIGINT          REFERENCES centers(id) ON DELETE SET NULL,
    warehouse_id    BIGINT          REFERENCES warehouses(id) ON DELETE SET NULL,
    provider_type   VARCHAR(20)     NOT NULL,
    webhook_url     VARCHAR(2048)   NOT NULL,
    enabled         BOOLEAN         NOT NULL DEFAULT TRUE,
    extra_config    TEXT,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhook_config_center ON webhook_endpoint_config (center_id);
CREATE INDEX idx_webhook_config_warehouse ON webhook_endpoint_config (warehouse_id);
CREATE INDEX idx_webhook_config_provider ON webhook_endpoint_config (provider_type);
CREATE INDEX idx_webhook_config_enabled ON webhook_endpoint_config (enabled);


-- ============================================================
-- Source: V31__notification_channel_config.sql
-- ============================================================
-- V31: Notification channel configuration table
-- Stores per-center/warehouse alert type channel configurations
-- Each row defines which channels (SMS, EMAIL, WEBHOOK) are enabled for a specific alert type

CREATE TABLE notification_channel_configs (
    id              BIGSERIAL       PRIMARY KEY,
    center_id       BIGINT          NOT NULL REFERENCES centers(id) ON DELETE CASCADE,
    warehouse_id    BIGINT          REFERENCES warehouses(id) ON DELETE CASCADE,
    alert_type      VARCHAR(50)     NOT NULL,
    channels        JSONB           NOT NULL DEFAULT '[]',
    active          BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_channel_config_scope UNIQUE (center_id, warehouse_id, alert_type)
);

COMMENT ON TABLE notification_channel_configs IS '알림 채널 설정 - 센터/창고 및 알림 유형별 채널 활성화 설정';
COMMENT ON COLUMN notification_channel_configs.id IS '알림 채널 설정 PK';
COMMENT ON COLUMN notification_channel_configs.center_id IS '센터 ID (필수)';
COMMENT ON COLUMN notification_channel_configs.warehouse_id IS '창고 ID (NULL이면 센터 전체 설정)';
COMMENT ON COLUMN notification_channel_configs.alert_type IS '알림 유형 (TEMPERATURE, HUMIDITY 등)';
COMMENT ON COLUMN notification_channel_configs.channels IS '채널 설정 JSON 배열 (예: [{"type":"SMS","enabled":true,"webhookProvider":null}])';
COMMENT ON COLUMN notification_channel_configs.active IS '설정 활성 여부';
COMMENT ON COLUMN notification_channel_configs.created_at IS '생성 시각 (UTC 기준 저장)';
COMMENT ON COLUMN notification_channel_configs.updated_at IS '수정 시각 (UTC 기준 저장)';

CREATE INDEX IF NOT EXISTS idx_channel_config_center_id
    ON notification_channel_configs (center_id);
CREATE INDEX IF NOT EXISTS idx_channel_config_warehouse_id
    ON notification_channel_configs (warehouse_id);
CREATE INDEX IF NOT EXISTS idx_channel_config_active
    ON notification_channel_configs (active);


-- ============================================================
-- Source: V32__ai_model_evaluations.sql
-- ============================================================
-- V32: AI model evaluation tracking table
-- Stores forecast accuracy metrics (MAE, RMSE, MAPE) per product and model version

CREATE TABLE analytics.ai_model_evaluations (
    id              BIGSERIAL       PRIMARY KEY,
    product_id      BIGINT          NOT NULL,
    mae             NUMERIC(12, 4)  NOT NULL,
    rmse            NUMERIC(12, 4)  NOT NULL,
    mape            NUMERIC(12, 4)  NOT NULL,
    evaluated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    model_version   VARCHAR(50)     NOT NULL DEFAULT 'prophet',
    CONSTRAINT fk_ai_model_evaluations_product FOREIGN KEY (product_id) REFERENCES public.products(id)
);

COMMENT ON TABLE analytics.ai_model_evaluations IS 'AI 모델 성능 평가 결과 - 상품별/모델버전별 예측 정확도 지표';
COMMENT ON COLUMN analytics.ai_model_evaluations.id IS '평가 결과 PK';
COMMENT ON COLUMN analytics.ai_model_evaluations.product_id IS '상품 ID (필수)';
COMMENT ON COLUMN analytics.ai_model_evaluations.mae IS 'Mean Absolute Error (평균절대오차)';
COMMENT ON COLUMN analytics.ai_model_evaluations.rmse IS 'Root Mean Squared Error (평균제곱근오차)';
COMMENT ON COLUMN analytics.ai_model_evaluations.mape IS 'Mean Absolute Percentage Error (%) (평균절대백분율오차)';
COMMENT ON COLUMN analytics.ai_model_evaluations.evaluated_at IS '평가 시각 (UTC 기준 저장)';
COMMENT ON COLUMN analytics.ai_model_evaluations.model_version IS '평가된 모델 버전 (예: prophet, statistical)';

CREATE INDEX idx_ai_model_evaluations_product_id
    ON analytics.ai_model_evaluations (product_id);
CREATE INDEX idx_ai_model_evaluations_evaluated_at
    ON analytics.ai_model_evaluations (evaluated_at DESC);
CREATE INDEX idx_ai_model_evaluations_model_version
    ON analytics.ai_model_evaluations (model_version);


-- ============================================================
-- Source: V33__add_shipped_quantity_to_fill_rate_source.sql
-- ============================================================
ALTER TABLE analytics.daily_fill_rate_source
    ADD COLUMN IF NOT EXISTS shipped_quantity INTEGER NOT NULL DEFAULT 0;


-- ============================================================
-- Source: V34__add_category_permissions.sql
-- ============================================================
INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
    ('CATEGORY_CREATE', 'Create categories'),
    ('CATEGORY_DELETE', 'Delete categories'),
    ('CATEGORY_READ', 'Read categories'),
    ('CATEGORY_UPDATE', 'Update categories')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN'
  AND p.code IN ('CATEGORY_CREATE', 'CATEGORY_DELETE', 'CATEGORY_READ', 'CATEGORY_UPDATE')
  AND NOT EXISTS (
      SELECT 1 FROM role_permissions existing
      WHERE existing.role_id = r.id
        AND existing.permission_id = p.id
  );

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN ('CATEGORY_CREATE', 'CATEGORY_READ', 'CATEGORY_UPDATE')
WHERE r.name = 'MANAGER'
  AND NOT EXISTS (
      SELECT 1 FROM role_permissions existing
      WHERE existing.role_id = r.id
        AND existing.permission_id = p.id
  );

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code = 'CATEGORY_READ'
WHERE r.name IN ('USER', 'STAFF')
  AND NOT EXISTS (
      SELECT 1 FROM role_permissions existing
      WHERE existing.role_id = r.id
        AND existing.permission_id = p.id
  );


-- ============================================================
-- Source: V35__normalize_environment_controller_target_axis.sql
-- ============================================================
UPDATE environment_controllers
SET target_axis = UPPER(target_axis)
WHERE target_axis IS NOT NULL
  AND target_axis <> UPPER(target_axis);


-- ============================================================
-- Source: V36__ai_suggestions.sql
-- ============================================================
CREATE TABLE analytics.ai_suggestions (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(100) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    summary VARCHAR(500),
    reason TEXT,
    recommended_action TEXT,
    target_type VARCHAR(100),
    target_id BIGINT,
    target_scope_type VARCHAR(50) NOT NULL,
    target_scope_id BIGINT NOT NULL,
    payload_json JSONB NOT NULL DEFAULT '{}',
    confidence_score DOUBLE PRECISION,
    source VARCHAR(100) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    created_by_user_id BIGINT,
    created_from_app VARCHAR(100),
    forecast_source_type VARCHAR(100),
    forecast_source_id BIGINT,
    forecast_model_version VARCHAR(100),
    forecast_generated_at TIMESTAMP WITH TIME ZONE,
    forecast_source_payload_json JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    visible_to_app VARCHAR(50) NOT NULL,
    approval_mode VARCHAR(100) NOT NULL,
    requested_on_behalf_user_id BIGINT,
    requested_scope_type VARCHAR(50),
    requested_scope_id BIGINT,
    expires_at TIMESTAMP WITH TIME ZONE,
    reviewed_by_user_id BIGINT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    approved_by_user_id BIGINT,
    approved_at TIMESTAMP WITH TIME ZONE,
    executed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    execution_result JSONB,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_suggestion_status
    ON analytics.ai_suggestions (status, id);

CREATE INDEX idx_ai_suggestion_scope
    ON analytics.ai_suggestions (target_scope_type, target_scope_id, status, id);


-- ============================================================
-- Source: V37__ai_suggestion_audits.sql
-- ============================================================
CREATE TABLE analytics.ai_suggestion_audits (
    id BIGSERIAL PRIMARY KEY,
    suggestion_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    approval_mode VARCHAR(100) NOT NULL,
    before_status VARCHAR(50),
    after_status VARCHAR(50),
    previous_status VARCHAR(50),
    next_status VARCHAR(50),
    before_payload_summary TEXT,
    after_payload_summary TEXT,
    actor_user_id BIGINT,
    actor_name VARCHAR(200),
    actor_role VARCHAR(100),
    target_type VARCHAR(100),
    target_id BIGINT,
    target_scope_type VARCHAR(50),
    target_scope_id BIGINT,
    request_id VARCHAR(100),
    result VARCHAR(50) NOT NULL,
    error_message TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_suggestion_audits_suggestion_id_recorded_at
    ON analytics.ai_suggestion_audits (suggestion_id, recorded_at);

CREATE INDEX idx_ai_suggestion_audits_action_recorded_at
    ON analytics.ai_suggestion_audits (action, recorded_at);


-- ============================================================
-- Source: V38__ai_suggestion_permissions.sql
-- ============================================================
INSERT INTO permissions (code, description)
SELECT source.code, source.description
FROM (VALUES
    ('AI_SUGGESTION_READ', 'Read AI suggestions'),
    ('AI_SUGGESTION_CREATE', 'Create AI suggestions'),
    ('AI_SUGGESTION_APPROVE', 'Approve AI suggestions'),
    ('AI_SUGGESTION_REJECT', 'Reject AI suggestions'),
    ('AI_SUGGESTION_EXECUTE', 'Execute approved AI suggestions')
) AS source (code, description)
WHERE NOT EXISTS (
    SELECT 1 FROM permissions target WHERE target.code = source.code
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'AI_SUGGESTION_READ',
    'AI_SUGGESTION_CREATE',
    'AI_SUGGESTION_APPROVE',
    'AI_SUGGESTION_REJECT',
    'AI_SUGGESTION_EXECUTE'
)
WHERE r.name IN ('ADMIN', 'MANAGER')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN ('AI_SUGGESTION_READ', 'AI_SUGGESTION_CREATE')
WHERE r.name IN ('USER', 'STAFF')
AND NOT EXISTS (
    SELECT 1 FROM role_permissions existing
    WHERE existing.role_id = r.id
      AND existing.permission_id = p.id
);


-- ============================================================
-- Source: V40__remove_locations.sql
-- ============================================================
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


COMMIT;

