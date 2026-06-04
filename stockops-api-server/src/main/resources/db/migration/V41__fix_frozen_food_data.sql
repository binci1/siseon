-- V41__fix_frozen_food_data.sql
-- Fix corrupted korean strings in V39

UPDATE categories SET name = '냉동식품' WHERE code = 'FROZEN_FOOD';
UPDATE categories SET name = '냉동간편식' WHERE code = 'FROZEN_READY_MEAL';
UPDATE categories SET name = '냉동육가공' WHERE code = 'FROZEN_MEAT';
UPDATE categories SET name = '냉동디저트' WHERE code = 'FROZEN_DESSERT';

UPDATE categories SET name = '만두/피자/핫도그' WHERE code = 'FROZEN_SNACK';
UPDATE categories SET name = '볶음밥/도시락' WHERE code = 'FROZEN_RICE';
UPDATE categories SET name = '너겟/돈까스' WHERE code = 'FROZEN_NUGGET';
UPDATE categories SET name = '아이스크림/빙수' WHERE code = 'FROZEN_ICE_CREAM';

UPDATE products SET name = '비비고 왕교자 490g*2', description = '쫄깃한 만두피와 속이 꽉 찬 왕교자', category = '만두/피자/핫도그' WHERE barcode = '8801007000001';
UPDATE products SET name = '풀무원 얇은피 꽉찬속 고기만두 400g', description = '얇은 피로 고기 육즙을 가득 채운 고기만두', category = '만두/피자/핫도그' WHERE barcode = '8801007000002';
UPDATE products SET name = '고메 마르게리따 피자 300g', description = '오븐에 구워 바삭한 도우와 깊은 치즈 풍미', category = '만두/피자/핫도그' WHERE barcode = '8801007000003';
UPDATE products SET name = '비비고 새우볶음밥 210g*4', description = '통통한 통새우가 가득한 고슬고슬한 볶음밥', category = '볶음밥/도시락' WHERE barcode = '8801007000004';
UPDATE products SET name = '하림 용가리치킨 300g', description = '아이들이 좋아하는 공룡 모양 치킨 너겟', category = '너겟/돈까스' WHERE barcode = '8801007000005';
UPDATE products SET name = '사조 안심 통살 돈까스 500g', description = '국내산 돼지고기 통살로 만든 바삭한 돈까스', category = '너겟/돈까스' WHERE barcode = '8801007000006';
UPDATE products SET name = '하겐다즈 바닐라 파인트 473ml', description = '깊고 진한 풍미의 프리미엄 바닐라 아이스크림', category = '아이스크림/빙수' WHERE barcode = '8801007000007';
UPDATE products SET name = '라라스윗 초콜릿 파인트 474ml', description = '칼로리 부담을 줄인 저칼로리 초콜릿 아이스크림', category = '아이스크림/빙수' WHERE barcode = '8801007000008';