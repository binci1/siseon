-- V44__initial_products.sql
-- 가상의 냉동식품 기업 "솔데식품" 브랜드 초기 품목 데이터
-- 실제 존재하는 브랜드/제품명을 사용하지 않습니다.
-- 바코드는 가상 prefix(9900001)를 사용합니다.

-- ============================================================
-- 1. 만두/교자 (FROZEN_DUMPLING) - 3개
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    (
        '9900001000101',
        '솔데식품 고기왕만두 500g',
        '두툼한 피에 국내산 돼지고기와 두부, 부추를 넣어 꽉 찬 속을 자랑하는 왕만두',
        '만두/교자',
        'EA',
        true,
        7500.00,
        120,
        (SELECT id FROM categories WHERE code = 'FROZEN_DUMPLING')
    ),
    (
        '9900001000102',
        '솔데식품 야채교자 400g',
        '신선한 배추김치와 당면, 두부를 넣은 담백하고 깔끔한 야채교자',
        '만두/교자',
        'EA',
        true,
        6500.00,
        100,
        (SELECT id FROM categories WHERE code = 'FROZEN_DUMPLING')
    ),
    (
        '9900001000103',
        '솔데식품 군만두 350g',
        '바삭한 겉면과 촉촉한 속이 조화로운 프라이팬 군만두. 간편하게 즐기는 일품 간식',
        '만두/교자',
        'EA',
        true,
        6000.00,
        80,
        (SELECT id FROM categories WHERE code = 'FROZEN_DUMPLING')
    );

-- ============================================================
-- 2. 피자/핫도그 (FROZEN_PIZZA) - 3개
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    (
        '9900001000201',
        '솔데식품 치즈피자 350g',
        '바삭한 씬 도우 위에 4가지 치즈를 듬뿍 올린 풍미 가득 치즈피자',
        '피자/핫도그',
        'EA',
        true,
        7000.00,
        60,
        (SELECT id FROM categories WHERE code = 'FROZEN_PIZZA')
    ),
    (
        '9900001000202',
        '솔데식품 클래식 핫도그 5입',
        '겉은 바삭 속은 촉촉한 클래식 스타일 핫도그. 에어프라이어로 간편하게',
        '피자/핫도그',
        'EA',
        true,
        5500.00,
        80,
        (SELECT id FROM categories WHERE code = 'FROZEN_PIZZA')
    ),
    (
        '9900001000203',
        '솔데식품 불고기피자 320g',
        '달콤한 불고기 소스와 양파, 모짜렐라 치즈가 어우러진 한국식 불고기피자',
        '피자/핫도그',
        'EA',
        true,
        7500.00,
        50,
        (SELECT id FROM categories WHERE code = 'FROZEN_PIZZA')
    );

-- ============================================================
-- 3. 볶음밥/도시락 (FROZEN_RICE) - 3개
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    (
        '9900001000301',
        '솔데식품 야채볶음밥 250g',
        '알알이 살아있는 밥에 옥수수, 당근, 완두콩을 넣어 볶은 담백한 야채볶음밥',
        '볶음밥/도시락',
        'EA',
        true,
        3800.00,
        150,
        (SELECT id FROM categories WHERE code = 'FROZEN_RICE')
    ),
    (
        '9900001000302',
        '솔데식품 김치볶음밥 250g',
        '잘 익은 묵은지를 넣어 깊은 김치 풍미를 살린 볶음밥. 전자레인지 3분이면 완성',
        '볶음밥/도시락',
        'EA',
        true,
        4000.00,
        150,
        (SELECT id FROM categories WHERE code = 'FROZEN_RICE')
    ),
    (
        '9900001000303',
        '솔데식품 참치마요볶음밥 250g',
        '통통한 참치와 고소한 마요네즈로 맛을 낸 참치마요 볶음밥',
        '볶음밥/도시락',
        'EA',
        true,
        4200.00,
        120,
        (SELECT id FROM categories WHERE code = 'FROZEN_RICE')
    );

-- ============================================================
-- 4. 너겟/돈까스 (FROZEN_NUGGET) - 3개
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    (
        '9900001000401',
        '솔데식품 치킨너겟 400g',
        '국내산 닭가슴살을 사용한 바삭하고 촉촉한 치킨너겟. 아이들이 좋아하는 한입 크기',
        '너겟/돈까스',
        'EA',
        true,
        8000.00,
        100,
        (SELECT id FROM categories WHERE code = 'FROZEN_NUGGET')
    ),
    (
        '9900001000402',
        '솔데식품 통살돈까스 500g',
        '국내산 돼지고기 등심을 통으로 사용한 두툼하고 바삭한 정통 돈까스',
        '너겟/돈까스',
        'EA',
        true,
        11000.00,
        60,
        (SELECT id FROM categories WHERE code = 'FROZEN_NUGGET')
    ),
    (
        '9900001000403',
        '솔데식품 치즈돈까스 450g',
        '바삭한 돈까스 속에 녹아드는 모짜렐라 치즈가 가득. 어린이 간식으로 제격',
        '너겟/돈까스',
        'EA',
        true,
        10000.00,
        60,
        (SELECT id FROM categories WHERE code = 'FROZEN_NUGGET')
    );

-- ============================================================
-- 5. 소시지/햄 (FROZEN_SAUSAGE) - 3개
-- ============================================================
INSERT INTO products (barcode, name, description, category, unit, expiry_managed, default_price, safety_stock_quantity, category_id)
VALUES
    (
        '9900001000501',
        '솔데식품 프리미엄 후랑크소시지 500g',
        '돼지고기 함량 85% 이상의 고품질 소시지. 껍질이 탱탱하고 육즙이 풍부',
        '소시지/햄',
        'EA',
        true,
        8500.00,
        80,
        (SELECT id FROM categories WHERE code = 'FROZEN_SAUSAGE')
    ),
    (
        '9900001000502',
        '솔데식품 스모크햄 300g',
        '저온 훈연 방식으로 깊은 향을 살린 슬라이스 스모크햄. 샌드위치에 제격',
        '소시지/햄',
        'EA',
        true,
        6500.00,
        70,
        (SELECT id FROM categories WHERE code = 'FROZEN_SAUSAGE')
    ),
    (
        '9900001000503',
        '솔데식품 미니 비엔나소시지 200g',
        '한입 크기로 즐기는 미니 비엔나. 도시락 반찬이나 간식으로 간편하게 활용',
        '소시지/햄',
        'EA',
        true,
        4500.00,
        100,
        (SELECT id FROM categories WHERE code = 'FROZEN_SAUSAGE')
    );
