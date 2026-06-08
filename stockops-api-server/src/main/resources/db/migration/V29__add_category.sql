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
-- 3. (REMOVED: SEED DATA MOVED TO LATER MIGRATION)
-- ============================================