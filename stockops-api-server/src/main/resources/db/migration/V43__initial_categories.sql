-- V43__initial_categories.sql
-- 냉장/냉동 콜드체인 회사 기준 카테고리 초기 데이터 (3단계 계층 구조)
-- 대분류(level 1) → 중분류(level 2) → 소분류(level 3)

-- ============================================================
-- 1. 대분류 (Level 1) - 2개
-- ============================================================
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동식품', 'FROZEN',  NULL, 1, 1, true),
    ('냉장식품', 'CHILLED', NULL, 1, 2, true);

-- ============================================================
-- 2. 중분류 (Level 2)
-- ============================================================

-- ── 냉동식품 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('냉동가공식품', 'FROZEN_PROCESSED', (SELECT id FROM categories WHERE code = 'FROZEN'), 2, 1, true),
    ('냉동수산물',   'FROZEN_SEAFOOD',   (SELECT id FROM categories WHERE code = 'FROZEN'), 2, 2, true),
    ('냉동육류',     'FROZEN_MEAT',      (SELECT id FROM categories WHERE code = 'FROZEN'), 2, 3, true);

-- ── 냉장식품 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('유제품',     'CHILLED_DAIRY',    (SELECT id FROM categories WHERE code = 'CHILLED'), 2, 1, true),
    ('냉장가공육', 'CHILLED_MEAT',     (SELECT id FROM categories WHERE code = 'CHILLED'), 2, 2, true),
    ('냉장음료',   'CHILLED_BEVERAGE', (SELECT id FROM categories WHERE code = 'CHILLED'), 2, 3, true);

-- ============================================================
-- 3. 소분류 (Level 3)
-- ============================================================

-- ── 냉동가공식품 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('만두/교자',     'FROZEN_DUMPLING', (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 1, true),
    ('피자/핫도그',   'FROZEN_PIZZA',    (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 2, true),
    ('볶음밥/도시락', 'FROZEN_RICE',     (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 3, true),
    ('냉동국/탕류',   'FROZEN_SOUP',     (SELECT id FROM categories WHERE code = 'FROZEN_PROCESSED'), 3, 4, true);

-- ── 냉동수산물 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('새우/오징어', 'FROZEN_SHELLFISH', (SELECT id FROM categories WHERE code = 'FROZEN_SEAFOOD'), 3, 1, true),
    ('생선필레',    'FROZEN_FISH',      (SELECT id FROM categories WHERE code = 'FROZEN_SEAFOOD'), 3, 2, true);

-- ── 냉동육류 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('너겟/돈까스', 'FROZEN_NUGGET',  (SELECT id FROM categories WHERE code = 'FROZEN_MEAT'), 3, 1, true),
    ('소시지/햄',   'FROZEN_SAUSAGE', (SELECT id FROM categories WHERE code = 'FROZEN_MEAT'), 3, 2, true);

-- ── 유제품 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('우유/두유',     'CHILLED_MILK',   (SELECT id FROM categories WHERE code = 'CHILLED_DAIRY'), 3, 1, true),
    ('요거트/발효유', 'CHILLED_YOGURT', (SELECT id FROM categories WHERE code = 'CHILLED_DAIRY'), 3, 2, true),
    ('치즈/버터',     'CHILLED_CHEESE', (SELECT id FROM categories WHERE code = 'CHILLED_DAIRY'), 3, 3, true);

-- ── 냉장가공육 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('햄/소시지',   'CHILLED_HAM',   (SELECT id FROM categories WHERE code = 'CHILLED_MEAT'), 3, 1, true),
    ('베이컨/삼겹살', 'CHILLED_BACON', (SELECT id FROM categories WHERE code = 'CHILLED_MEAT'), 3, 2, true);

-- ── 냉장음료 하위
INSERT INTO categories (name, code, parent_id, level, sort_order, active) VALUES
    ('주스/음료',   'CHILLED_JUICE',  (SELECT id FROM categories WHERE code = 'CHILLED_BEVERAGE'), 3, 1, true),
    ('커피/유음료', 'CHILLED_COFFEE', (SELECT id FROM categories WHERE code = 'CHILLED_BEVERAGE'), 3, 2, true);
