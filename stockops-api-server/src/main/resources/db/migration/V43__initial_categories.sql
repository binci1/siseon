-- V43__initial_categories.sql
-- 냉동식품 콜드체인 회사 기준 카테고리 초기 데이터 (3단계 계층 구조)
-- 대분류(level 1) → 중분류(level 2) → 소분류(level 3)

-- ============================================================
-- 1. 대분류 (Level 1) - 1개
-- ============================================================
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동식품', 'FROZEN', NULL, 1, 1, true);

-- ============================================================
-- 2. 중분류 (Level 2)
-- ============================================================
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동가공식품', 'FROZEN_PROCESSED', (SELECT id FROM categories WHERE code = 'FROZEN'), 2, 1, true),
    ('냉동육류',     'FROZEN_MEAT',      (SELECT id FROM categories WHERE code = 'FROZEN'), 2, 2, true);

-- ============================================================
-- 3. 소분류 (Level 3)
-- ============================================================

-- ── 냉동가공식품 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('만두/교자',     'FROZEN_DUMPLING', (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 1, true),
    ('피자/핫도그',   'FROZEN_PIZZA',    (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 2, true),
    ('볶음밥/도시락', 'FROZEN_RICE',     (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 3, true);

-- ── 냉동육류 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('너겟/돈까스', 'FROZEN_NUGGET',  (SELECT id FROM categories WHERE code = 'FROZEN_MEAT'), 3, 1, true),
    ('소시지/햄',   'FROZEN_SAUSAGE', (SELECT id FROM categories WHERE code = 'FROZEN_MEAT'), 3, 2, true);
