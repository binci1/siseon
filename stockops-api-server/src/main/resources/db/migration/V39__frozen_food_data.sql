-- V39__frozen_food_data.sql
-- Add Frozen Food categories and products for demo purposes

-- 1. Insert New Categories (FROZEN_FOOD)
INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES ('냉동식품', 'FROZEN_FOOD', NULL, 1, 4, true);

INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES 
    ('냉동간편식', 'FROZEN_READY_MEAL', (SELECT id FROM categories WHERE code = 'FROZEN_FOOD'), 2, 1, true),
    ('냉동육가공', 'FROZEN_MEAT', (SELECT id FROM categories WHERE code = 'FROZEN_FOOD'), 2, 2, true),
    ('냉동디저트', 'FROZEN_DESSERT', (SELECT id FROM categories WHERE code = 'FROZEN_FOOD'), 2, 3, true);

INSERT INTO categories (name, code, parent_id, level, sort_order, active)
VALUES
    ('만두/피자/핫도그', 'FROZEN_SNACK', (SELECT id FROM categories WHERE code = 'FROZEN_READY_MEAL'), 3, 1, true),
    ('볶음밥/도시락', 'FROZEN_RICE', (SELECT id FROM categories WHERE code = 'FROZEN_READY_MEAL'), 3, 2, true),
    ('너겟/돈까스', 'FROZEN_NUGGET', (SELECT id FROM categories WHERE code = 'FROZEN_MEAT'), 3, 1, true),
    ('아이스크림/빙수', 'FROZEN_ICE_CREAM', (SELECT id FROM categories WHERE code = 'FROZEN_DESSERT'), 3, 1, true);

-- 2. Insert Products
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    ('8801007000001', '비비고 왕교자 490g*2', '쫄깃한 만두피와 꽉 찬 속이 일품인 왕교자', '만두/피자/핫도그', 'EA', true, 8900.00, 100, (SELECT id FROM categories WHERE code = 'FROZEN_SNACK')),
    ('8801007000002', '풀무원 얇은피 꽉찬속 고기만두 400g', '얇은 피로 고기 육즙을 가득 채운 고기만두', '만두/피자/핫도그', 'EA', true, 7900.00, 50, (SELECT id FROM categories WHERE code = 'FROZEN_SNACK')),
    ('8801007000003', '고메 마르게리타 피자 300g', '오븐에 구워 바삭한 도우와 깊은 치즈 풍미', '만두/피자/핫도그', 'EA', true, 6500.00, 30, (SELECT id FROM categories WHERE code = 'FROZEN_SNACK')),
    ('8801007000004', '비비고 새우볶음밥 210g*4', '탱글탱글한 통새우가 가득한 고슬고슬한 볶음밥', '볶음밥/도시락', 'EA', true, 11000.00, 80, (SELECT id FROM categories WHERE code = 'FROZEN_RICE')),
    ('8801007000005', '하림 용가리 치킨 300g', '아이들이 좋아하는 공룡 모양 치킨 너겟', '너겟/돈까스', 'EA', true, 8500.00, 60, (SELECT id FROM categories WHERE code = 'FROZEN_NUGGET')),
    ('8801007000006', '사조 대림 통살 돈까스 500g', '국내산 돼지고기 통살로 만든 바삭한 돈까스', '너겟/돈까스', 'EA', true, 9500.00, 40, (SELECT id FROM categories WHERE code = 'FROZEN_NUGGET')),
    ('8801007000007', '하겐다즈 바닐라 파인트 473ml', '깊고 진한 풍미의 프리미엄 바닐라 아이스크림', '아이스크림/빙수', 'EA', true, 14500.00, 20, (SELECT id FROM categories WHERE code = 'FROZEN_ICE_CREAM')),
    ('8801007000008', '라라스윗 초콜릿 파인트 474ml', '칼로리 부담을 줄인 저칼로리 초콜릿 아이스크림', '아이스크림/빙수', 'EA', true, 8900.00, 25, (SELECT id FROM categories WHERE code = 'FROZEN_ICE_CREAM'));
