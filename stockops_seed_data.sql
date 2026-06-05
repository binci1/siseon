-- ============================================================
-- StockOps 초기 데이터 스크립트 (독립 실행용)
-- 대상 DB: PostgreSQL (버전 무관)
-- 포함 내용: 센터, 창고, 카테고리, 품목, 로트, 재고
--
-- 사용법:
--   psql -h <HOST> -U <USER> -d <DBNAME> -f stockops_seed_data.sql
--
-- 주의사항:
--   - 반드시 StockOps 스키마(테이블)가 먼저 생성된 상태여야 합니다.
--     (Spring Boot 앱 첫 실행 시 Flyway가 자동 생성)
--   - 이미 데이터가 있는 DB에 실행하면 중복 오류가 발생할 수 있습니다.
--   - 외래 키 순서에 맞게 작성되었으므로 순서대로 실행하세요.
-- ============================================================

BEGIN;

-- ============================================================
-- 1. 센터 (centers) - 5개
-- ============================================================
INSERT INTO centers (code, name, address, phone, status) VALUES
    ('CT-SEL', '서울 물류센터', '서울특별시 강서구 공항대로 219',           '02-1234-5000',  'ACTIVE'),
    ('CT-ICN', '인천 물류센터', '인천광역시 서구 청라동 청라국제대로 25',    '032-1234-5000', 'ACTIVE'),
    ('CT-PUS', '부산 물류센터', '부산광역시 강서구 명지국제5로 51',          '051-1234-5000', 'ACTIVE'),
    ('CT-DAE', '대구 물류센터', '대구광역시 달성군 구지면 국가산업단로 10',  '053-1234-5000', 'ACTIVE'),
    ('CT-GWJ', '광주 물류센터', '광주광역시 광산구 하남산단6번로 127',       '062-1234-5000', 'ACTIVE');

-- ============================================================
-- 2. 창고 (warehouses) - 8개
-- ============================================================
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    ((SELECT id FROM centers WHERE code='CT-SEL'), 'WH-SEL-01', '서울 강서 창고',    '서울특별시 강서구 공항대로 219 A동',             '02-1234-5001',  'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-SEL'), 'WH-SEL-02', '서울 금천 창고',    '서울특별시 금천구 디지털로 130 B동',             '02-1234-5002',  'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-ICN'), 'WH-ICN-01', '인천 송도 창고',    '인천광역시 연수구 송도과학로 32 1동',            '032-1234-5001', 'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-ICN'), 'WH-ICN-02', '인천 부평 창고',    '인천광역시 부평구 경인로 543 2동',               '032-1234-5002', 'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-PUS'), 'WH-PUS-01', '부산 강서 신항 창고','부산광역시 강서구 명지국제5로 51 1동',           '051-1234-5001', 'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-PUS'), 'WH-PUS-02', '부산 사상 창고',    '부산광역시 사상구 학감대로 133 2동',             '051-1234-5002', 'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-DAE'), 'WH-DAE-01', '대구 달성 창고',    '대구광역시 달성군 구지면 국가산업단로 10 A동',   '053-1234-5001', 'ACTIVE'),
    ((SELECT id FROM centers WHERE code='CT-GWJ'), 'WH-GWJ-01', '광주 하남 창고',    '광주광역시 광산구 하남산단6번로 127 A동',        '062-1234-5001', 'ACTIVE');

-- ============================================================
-- 3. 카테고리 (categories) - 7개 (대/중/소 3단계)
-- ============================================================

-- 대분류
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동식품', 'FROZEN', NULL, 1, 1, true);

-- 중분류
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동가공식품', 'FROZEN_PROCESSED', (SELECT id FROM categories WHERE code='FROZEN'), 2, 1, true),
    ('냉동육류',     'FROZEN_MEAT',      (SELECT id FROM categories WHERE code='FROZEN'), 2, 2, true);

-- 소분류
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('만두/교자',     'FROZEN_DUMPLING', (SELECT id FROM categories WHERE code='FROZEN_PROCESSED'), 3, 1, true),
    ('피자/핫도그',   'FROZEN_PIZZA',    (SELECT id FROM categories WHERE code='FROZEN_PROCESSED'), 3, 2, true),
    ('볶음밥/도시락', 'FROZEN_RICE',     (SELECT id FROM categories WHERE code='FROZEN_PROCESSED'), 3, 3, true),
    ('너겟/돈까스',   'FROZEN_NUGGET',   (SELECT id FROM categories WHERE code='FROZEN_MEAT'),      3, 1, true),
    ('소시지/햄',     'FROZEN_SAUSAGE',  (SELECT id FROM categories WHERE code='FROZEN_MEAT'),      3, 2, true);

-- ============================================================
-- 4. 품목 (products) - 15개 (솔데식품 브랜드, 가상)
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id) VALUES
    -- 만두/교자
    ('9900001000101', '솔데식품 고기왕만두 500g',       '두툼한 피에 국내산 돼지고기와 두부, 부추를 넣어 꽉 찬 속을 자랑하는 왕만두',  '만두/교자',     'EA', true,  7500.00, 120, (SELECT id FROM categories WHERE code='FROZEN_DUMPLING')),
    ('9900001000102', '솔데식품 야채교자 400g',          '신선한 배추김치와 당면, 두부를 넣은 담백하고 깔끔한 야채교자',                '만두/교자',     'EA', true,  6500.00, 100, (SELECT id FROM categories WHERE code='FROZEN_DUMPLING')),
    ('9900001000103', '솔데식품 군만두 350g',            '바삭한 겉면과 촉촉한 속이 조화로운 프라이팬 군만두',                         '만두/교자',     'EA', true,  6000.00,  80, (SELECT id FROM categories WHERE code='FROZEN_DUMPLING')),
    -- 피자/핫도그
    ('9900001000201', '솔데식품 치즈피자 350g',          '바삭한 씬 도우 위에 4가지 치즈를 듬뿍 올린 풍미 가득 치즈피자',              '피자/핫도그',   'EA', true,  7000.00,  60, (SELECT id FROM categories WHERE code='FROZEN_PIZZA')),
    ('9900001000202', '솔데식품 클래식 핫도그 5입',      '겉은 바삭 속은 촉촉한 클래식 스타일 핫도그. 에어프라이어로 간편하게',        '피자/핫도그',   'EA', true,  5500.00,  80, (SELECT id FROM categories WHERE code='FROZEN_PIZZA')),
    ('9900001000203', '솔데식품 불고기피자 320g',        '달콤한 불고기 소스와 양파, 모짜렐라 치즈가 어우러진 한국식 불고기피자',      '피자/핫도그',   'EA', true,  7500.00,  50, (SELECT id FROM categories WHERE code='FROZEN_PIZZA')),
    -- 볶음밥/도시락
    ('9900001000301', '솔데식품 야채볶음밥 250g',        '알알이 살아있는 밥에 옥수수, 당근, 완두콩을 넣어 볶은 담백한 야채볶음밥',    '볶음밥/도시락', 'EA', true,  3800.00, 150, (SELECT id FROM categories WHERE code='FROZEN_RICE')),
    ('9900001000302', '솔데식품 김치볶음밥 250g',        '잘 익은 묵은지를 넣어 깊은 김치 풍미를 살린 볶음밥. 전자레인지 3분이면 완성', '볶음밥/도시락', 'EA', true,  4000.00, 150, (SELECT id FROM categories WHERE code='FROZEN_RICE')),
    ('9900001000303', '솔데식품 참치마요볶음밥 250g',    '통통한 참치와 고소한 마요네즈로 맛을 낸 참치마요 볶음밥',                    '볶음밥/도시락', 'EA', true,  4200.00, 120, (SELECT id FROM categories WHERE code='FROZEN_RICE')),
    -- 너겟/돈까스
    ('9900001000401', '솔데식품 치킨너겟 400g',          '국내산 닭가슴살을 사용한 바삭하고 촉촉한 치킨너겟',                         '너겟/돈까스',   'EA', true,  8000.00, 100, (SELECT id FROM categories WHERE code='FROZEN_NUGGET')),
    ('9900001000402', '솔데식품 통살돈까스 500g',        '국내산 돼지고기 등심을 통으로 사용한 두툼하고 바삭한 정통 돈까스',           '너겟/돈까스',   'EA', true, 11000.00,  60, (SELECT id FROM categories WHERE code='FROZEN_NUGGET')),
    ('9900001000403', '솔데식품 치즈돈까스 450g',        '바삭한 돈까스 속에 녹아드는 모짜렐라 치즈가 가득. 어린이 간식으로 제격',    '너겟/돈까스',   'EA', true, 10000.00,  60, (SELECT id FROM categories WHERE code='FROZEN_NUGGET')),
    -- 소시지/햄
    ('9900001000501', '솔데식품 프리미엄 후랑크소시지 500g', '돼지고기 함량 85% 이상의 고품질 소시지. 껍질이 탱탱하고 육즙이 풍부',  '소시지/햄',     'EA', true,  8500.00,  80, (SELECT id FROM categories WHERE code='FROZEN_SAUSAGE')),
    ('9900001000502', '솔데식품 스모크햄 300g',          '저온 훈연 방식으로 깊은 향을 살린 슬라이스 스모크햄',                        '소시지/햄',     'EA', true,  6500.00,  70, (SELECT id FROM categories WHERE code='FROZEN_SAUSAGE')),
    ('9900001000503', '솔데식품 미니 비엔나소시지 200g', '한입 크기로 즐기는 미니 비엔나. 도시락 반찬이나 간식으로 간편하게 활용',    '소시지/햄',     'EA', true,  4500.00, 100, (SELECT id FROM categories WHERE code='FROZEN_SAUSAGE'));

-- ============================================================
-- 5. 로트 (lots) - 15개 (품목당 1개, 2026-05-01 입고)
-- ============================================================
INSERT INTO lots (lot_number, product_id, expiry_date, received_date, quantity, status) VALUES
    ('LOT-2026-001', (SELECT id FROM products WHERE barcode='9900001000101'), '2027-11-30', '2026-05-01', 1920, 'ACTIVE'),
    ('LOT-2026-002', (SELECT id FROM products WHERE barcode='9900001000102'), '2027-11-30', '2026-05-01', 1590, 'ACTIVE'),
    ('LOT-2026-003', (SELECT id FROM products WHERE barcode='9900001000103'), '2027-11-30', '2026-05-01', 1275, 'ACTIVE'),
    ('LOT-2026-004', (SELECT id FROM products WHERE barcode='9900001000201'), '2027-08-31', '2026-05-01',  960, 'ACTIVE'),
    ('LOT-2026-005', (SELECT id FROM products WHERE barcode='9900001000202'), '2027-08-31', '2026-05-01', 1275, 'ACTIVE'),
    ('LOT-2026-006', (SELECT id FROM products WHERE barcode='9900001000203'), '2027-08-31', '2026-05-01',  795, 'ACTIVE'),
    ('LOT-2026-007', (SELECT id FROM products WHERE barcode='9900001000301'), '2027-05-31', '2026-05-01', 2390, 'ACTIVE'),
    ('LOT-2026-008', (SELECT id FROM products WHERE barcode='9900001000302'), '2027-05-31', '2026-05-01', 2390, 'ACTIVE'),
    ('LOT-2026-009', (SELECT id FROM products WHERE barcode='9900001000303'), '2027-05-31', '2026-05-01', 1905, 'ACTIVE'),
    ('LOT-2026-010', (SELECT id FROM products WHERE barcode='9900001000401'), '2028-02-28', '2026-05-01', 1590, 'ACTIVE'),
    ('LOT-2026-011', (SELECT id FROM products WHERE barcode='9900001000402'), '2028-02-28', '2026-05-01',  960, 'ACTIVE'),
    ('LOT-2026-012', (SELECT id FROM products WHERE barcode='9900001000403'), '2028-02-28', '2026-05-01',  960, 'ACTIVE'),
    ('LOT-2026-013', (SELECT id FROM products WHERE barcode='9900001000501'), '2027-11-30', '2026-05-01', 1275, 'ACTIVE'),
    ('LOT-2026-014', (SELECT id FROM products WHERE barcode='9900001000502'), '2027-11-30', '2026-05-01', 1110, 'ACTIVE'),
    ('LOT-2026-015', (SELECT id FROM products WHERE barcode='9900001000503'), '2027-11-30', '2026-05-01', 1590, 'ACTIVE');

-- ============================================================
-- 6. 재고 (inventory) - 120개 (15품목 × 8창고)
-- 배분 비율: SEL-01(3.0x) SEL-02(2.5x) ICN-01(2.0x) ICN-02(1.8x)
--            PUS-01(2.0x) PUS-02(1.8x) DAE-01(1.5x) GWJ-01(1.3x)
-- ============================================================
INSERT INTO inventory (product_id, warehouse_id, lot_id, quantity, reserved_quantity) VALUES
-- 고기왕만두
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),360,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),220,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),220,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000101'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-001'),160,0),
-- 야채교자
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),250,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000102'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-002'),130,0),
-- 군만두
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000103'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-003'),105,0),
-- 치즈피자
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 90,0),
    ((SELECT id FROM products WHERE barcode='9900001000201'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-004'), 80,0),
-- 클래식 핫도그
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000202'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-005'),105,0),
-- 불고기피자
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'),125,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'),100,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 90,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'),100,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 90,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 75,0),
    ((SELECT id FROM products WHERE barcode='9900001000203'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-006'), 65,0),
-- 야채볶음밥
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),450,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),375,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),270,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),270,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),225,0),
    ((SELECT id FROM products WHERE barcode='9900001000301'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-007'),200,0),
-- 김치볶음밥
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),450,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),375,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),270,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),270,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),225,0),
    ((SELECT id FROM products WHERE barcode='9900001000302'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-008'),200,0),
-- 참치마요볶음밥
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),360,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),215,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),215,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000303'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-009'),155,0),
-- 치킨너겟
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),250,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000401'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-010'),130,0),
-- 통살돈까스
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 90,0),
    ((SELECT id FROM products WHERE barcode='9900001000402'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-011'), 80,0),
-- 치즈돈까스
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'),110,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 90,0),
    ((SELECT id FROM products WHERE barcode='9900001000403'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-012'), 80,0),
-- 프리미엄 후랑크소시지
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),240,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),160,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),145,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),120,0),
    ((SELECT id FROM products WHERE barcode='9900001000501'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-013'),105,0),
-- 스모크햄
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),210,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),175,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),140,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),125,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),140,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),125,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'),105,0),
    ((SELECT id FROM products WHERE barcode='9900001000502'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-014'), 90,0),
-- 미니 비엔나소시지
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-SEL-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),300,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-SEL-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),250,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-ICN-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-ICN-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-PUS-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),200,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-PUS-02'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),180,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-DAE-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),150,0),
    ((SELECT id FROM products WHERE barcode='9900001000503'),(SELECT id FROM warehouses WHERE code='WH-GWJ-01'),(SELECT id FROM lots WHERE lot_number='LOT-2026-015'),130,0);

COMMIT;
