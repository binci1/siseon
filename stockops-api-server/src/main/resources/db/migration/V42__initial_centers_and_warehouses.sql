-- V42__initial_centers_and_warehouses.sql
-- 한국 주요 거점의 물류센터 5개 및 창고 8개 초기 데이터

-- ============================================================
-- 1. 센터 (Centers) - 5개
-- ============================================================
INSERT INTO centers (code, name, address, phone, status) VALUES
    ('CT-SEL', '서울 물류센터',   '서울특별시 강서구 공항대로 219',            '02-1234-5000', 'ACTIVE'),
    ('CT-ICN', '인천 물류센터',   '인천광역시 서구 청라동 청라국제대로 25',     '032-1234-5000', 'ACTIVE'),
    ('CT-PUS', '부산 물류센터',   '부산광역시 강서구 명지국제5로 51',          '051-1234-5000', 'ACTIVE'),
    ('CT-DAE', '대구 물류센터',   '대구광역시 달성군 구지면 국가산업단로 10',  '053-1234-5000', 'ACTIVE'),
    ('CT-GWJ', '광주 물류센터',   '광주광역시 광산구 하남산단6번로 127',       '062-1234-5000', 'ACTIVE');

-- ============================================================
-- 2. 창고 (Warehouses) - 8개
-- 서울 2개 / 인천 2개 / 부산 2개 / 대구 1개 / 광주 1개
-- ============================================================

-- 서울 물류센터 산하 창고
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    (
        (SELECT id FROM centers WHERE code = 'CT-SEL'),
        'WH-SEL-01',
        '서울 강서 창고',
        '서울특별시 강서구 공항대로 219 A동',
        '02-1234-5001',
        'ACTIVE'
    ),
    (
        (SELECT id FROM centers WHERE code = 'CT-SEL'),
        'WH-SEL-02',
        '서울 금천 창고',
        '서울특별시 금천구 디지털로 130 B동',
        '02-1234-5002',
        'ACTIVE'
    );

-- 인천 물류센터 산하 창고
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    (
        (SELECT id FROM centers WHERE code = 'CT-ICN'),
        'WH-ICN-01',
        '인천 송도 창고',
        '인천광역시 연수구 송도과학로 32 1동',
        '032-1234-5001',
        'ACTIVE'
    ),
    (
        (SELECT id FROM centers WHERE code = 'CT-ICN'),
        'WH-ICN-02',
        '인천 부평 창고',
        '인천광역시 부평구 경인로 543 2동',
        '032-1234-5002',
        'ACTIVE'
    );

-- 부산 물류센터 산하 창고
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    (
        (SELECT id FROM centers WHERE code = 'CT-PUS'),
        'WH-PUS-01',
        '부산 강서 신항 창고',
        '부산광역시 강서구 명지국제5로 51 1동',
        '051-1234-5001',
        'ACTIVE'
    ),
    (
        (SELECT id FROM centers WHERE code = 'CT-PUS'),
        'WH-PUS-02',
        '부산 사상 창고',
        '부산광역시 사상구 학감대로 133 2동',
        '051-1234-5002',
        'ACTIVE'
    );

-- 대구 물류센터 산하 창고
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    (
        (SELECT id FROM centers WHERE code = 'CT-DAE'),
        'WH-DAE-01',
        '대구 달성 창고',
        '대구광역시 달성군 구지면 국가산업단로 10 A동',
        '053-1234-5001',
        'ACTIVE'
    );

-- 광주 물류센터 산하 창고
INSERT INTO warehouses (center_id, code, name, address, phone, status) VALUES
    (
        (SELECT id FROM centers WHERE code = 'CT-GWJ'),
        'WH-GWJ-01',
        '광주 하남 창고',
        '광주광역시 광산구 하남산단6번로 127 A동',
        '062-1234-5001',
        'ACTIVE'
    );
