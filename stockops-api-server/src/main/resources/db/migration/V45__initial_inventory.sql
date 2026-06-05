-- V45__initial_inventory.sql
-- 솔데식품 15개 품목 초기 재고 배치
-- 직원 500명 / 5센터 / 8창고 규모 기준
--
-- 창고별 재고 배분 비율 (안전재고 대비 배수)
--   서울 강서  (WH-SEL-01) : 3.0x  ─┐ 수도권 주력 거점
--   서울 금천  (WH-SEL-02) : 2.5x  ─┘
--   인천 송도  (WH-ICN-01) : 2.0x  ─┐ 항만·수출입 거점
--   인천 부평  (WH-ICN-02) : 1.8x  ─┘
--   부산 신항  (WH-PUS-01) : 2.0x  ─┐ 남부 물류 거점
--   부산 사상  (WH-PUS-02) : 1.8x  ─┘
--   대구 달성  (WH-DAE-01) : 1.5x    지역 거점
--   광주 하남  (WH-GWJ-01) : 1.3x    지역 거점

-- ============================================================
-- 1. 로트 생성 (품목당 1개 — 2026-05-01 입고 기준)
-- ============================================================
INSERT INTO lots (lot_number, product_id, expiry_date, received_date, quantity, status) VALUES
    -- 만두/교자 (유통기한 18개월)
    ('LOT-2026-001', (SELECT id FROM products WHERE barcode = '9900001000101'), '2027-11-30', '2026-05-01', 1920, 'ACTIVE'),
    ('LOT-2026-002', (SELECT id FROM products WHERE barcode = '9900001000102'), '2027-11-30', '2026-05-01', 1590, 'ACTIVE'),
    ('LOT-2026-003', (SELECT id FROM products WHERE barcode = '9900001000103'), '2027-11-30', '2026-05-01', 1275, 'ACTIVE'),
    -- 피자/핫도그 (유통기한 15개월)
    ('LOT-2026-004', (SELECT id FROM products WHERE barcode = '9900001000201'), '2027-08-31', '2026-05-01',  960, 'ACTIVE'),
    ('LOT-2026-005', (SELECT id FROM products WHERE barcode = '9900001000202'), '2027-08-31', '2026-05-01', 1275, 'ACTIVE'),
    ('LOT-2026-006', (SELECT id FROM products WHERE barcode = '9900001000203'), '2027-08-31', '2026-05-01',  795, 'ACTIVE'),
    -- 볶음밥/도시락 (유통기한 12개월)
    ('LOT-2026-007', (SELECT id FROM products WHERE barcode = '9900001000301'), '2027-05-31', '2026-05-01', 2390, 'ACTIVE'),
    ('LOT-2026-008', (SELECT id FROM products WHERE barcode = '9900001000302'), '2027-05-31', '2026-05-01', 2390, 'ACTIVE'),
    ('LOT-2026-009', (SELECT id FROM products WHERE barcode = '9900001000303'), '2027-05-31', '2026-05-01', 1905, 'ACTIVE'),
    -- 너겟/돈까스 (유통기한 21개월)
    ('LOT-2026-010', (SELECT id FROM products WHERE barcode = '9900001000401'), '2028-02-28', '2026-05-01', 1590, 'ACTIVE'),
    ('LOT-2026-011', (SELECT id FROM products WHERE barcode = '9900001000402'), '2028-02-28', '2026-05-01',  960, 'ACTIVE'),
    ('LOT-2026-012', (SELECT id FROM products WHERE barcode = '9900001000403'), '2028-02-28', '2026-05-01',  960, 'ACTIVE'),
    -- 소시지/햄 (유통기한 18개월)
    ('LOT-2026-013', (SELECT id FROM products WHERE barcode = '9900001000501'), '2027-11-30', '2026-05-01', 1275, 'ACTIVE'),
    ('LOT-2026-014', (SELECT id FROM products WHERE barcode = '9900001000502'), '2027-11-30', '2026-05-01', 1110, 'ACTIVE'),
    ('LOT-2026-015', (SELECT id FROM products WHERE barcode = '9900001000503'), '2027-11-30', '2026-05-01', 1590, 'ACTIVE');

-- ============================================================
-- 2. 재고 배치 (15 품목 × 8 창고 = 120 레코드)
-- ============================================================

-- ── 솔데식품 고기왕만두 500g (LOT-2026-001) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 360, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 220, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 220, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000101'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-001'), 160, 0);

-- ── 솔데식품 야채교자 400g (LOT-2026-002) ────────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 250, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000102'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-002'), 130, 0);

-- ── 솔데식품 군만두 350g (LOT-2026-003) ──────────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000103'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-003'), 105, 0);

-- ── 솔데식품 치즈피자 350g (LOT-2026-004) ────────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'),  90, 0),
    ((SELECT id FROM products WHERE barcode='9900001000201'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-004'),  80, 0);

-- ── 솔데식품 클래식 핫도그 5입 (LOT-2026-005) ────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000202'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-005'), 105, 0);

-- ── 솔데식품 불고기피자 320g (LOT-2026-006) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 125, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 100, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'),  90, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 100, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'),  90, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'),  75, 0),
    ((SELECT id FROM products WHERE barcode='9900001000203'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-006'),  65, 0);

-- ── 솔데식품 야채볶음밥 250g (LOT-2026-007) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 450, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 375, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 270, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 270, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 225, 0),
    ((SELECT id FROM products WHERE barcode='9900001000301'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-007'), 200, 0);

-- ── 솔데식품 김치볶음밥 250g (LOT-2026-008) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 450, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 375, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 270, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 270, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 225, 0),
    ((SELECT id FROM products WHERE barcode='9900001000302'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-008'), 200, 0);

-- ── 솔데식품 참치마요볶음밥 250g (LOT-2026-009) ──────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 360, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 215, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 215, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000303'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-009'), 155, 0);

-- ── 솔데식품 치킨너겟 400g (LOT-2026-010) ────────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 250, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000401'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-010'), 130, 0);

-- ── 솔데식품 통살돈까스 500g (LOT-2026-011) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'),  90, 0),
    ((SELECT id FROM products WHERE barcode='9900001000402'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-011'),  80, 0);

-- ── 솔데식품 치즈돈까스 450g (LOT-2026-012) ──────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 110, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'),  90, 0),
    ((SELECT id FROM products WHERE barcode='9900001000403'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-012'),  80, 0);

-- ── 솔데식품 프리미엄 후랑크소시지 500g (LOT-2026-013) ───────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 240, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 160, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 145, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 120, 0),
    ((SELECT id FROM products WHERE barcode='9900001000501'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-013'), 105, 0);

-- ── 솔데식품 스모크햄 300g (LOT-2026-014) ────────────────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 210, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 175, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 140, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 125, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 140, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 125, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 105, 0),
    ((SELECT id FROM products WHERE barcode='9900001000502'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-014'),  90, 0);

-- ── 솔데식품 미니 비엔나소시지 200g (LOT-2026-015) ───────────
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-SEL-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 300, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-SEL-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 250, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-ICN-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-ICN-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-PUS-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 200, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-PUS-02'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 180, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-DAE-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 150, 0),
    ((SELECT id FROM products WHERE barcode='9900001000503'), (SELECT id FROM warehouses WHERE code='WH-GWJ-01'), (SELECT id FROM lots WHERE lot_number='LOT-2026-015'), 130, 0);
