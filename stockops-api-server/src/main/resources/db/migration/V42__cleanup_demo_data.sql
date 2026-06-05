-- V42__cleanup_demo_data.sql
-- 기존에 임시로 삽입된 데모/테스트 데이터를 모두 삭제합니다.
-- 재배포 시 빈 상태(스키마 + 관리자 계정만 남음)로 시작하기 위해 실행됩니다.
-- 외래 키 제약조건 순서에 따라 자식 테이블부터 삭제합니다.

-- ============================================================
-- 1. 환경 모니터링 관련 데이터
-- ============================================================
DELETE FROM controller_commands;
DELETE FROM environment_alerts;
DELETE FROM sensor_readings;
DELETE FROM sensor_latest;
DELETE FROM environment_controllers;
DELETE FROM sensor_devices;

-- ============================================================
-- 2. AI / 분석 관련 데이터
-- ============================================================
DELETE FROM ai_suggestion_audits;
DELETE FROM ai_suggestions;
DELETE FROM ai_model_evaluations;
DELETE FROM demand_forecasts;
DELETE FROM analytics_snapshots WHERE TRUE;

-- ============================================================
-- 3. 알림 / 에스컬레이션 관련 데이터
-- ============================================================
DELETE FROM escalation_logs WHERE TRUE;
DELETE FROM pending_alerts WHERE TRUE;
DELETE FROM notification_channel_config WHERE TRUE;
DELETE FROM webhook_endpoint_config WHERE TRUE;

-- ============================================================
-- 4. 재고 실사 (사이클 카운트)
-- ============================================================
DELETE FROM cycle_count_items WHERE TRUE;
DELETE FROM cycle_counts WHERE TRUE;

-- ============================================================
-- 5. 재고 이동 (재고 조정, 창고 간 이동)
-- ============================================================
DELETE FROM stock_adjustments WHERE TRUE;
DELETE FROM inventory_transfers WHERE TRUE;
DELETE FROM inventory_transactions WHERE TRUE;

-- ============================================================
-- 6. 재고 / 로트
-- ============================================================
DELETE FROM inventory WHERE TRUE;
DELETE FROM expiry_quarantine_items WHERE TRUE;
DELETE FROM lots WHERE TRUE;

-- ============================================================
-- 7. 입고 / 출고
-- ============================================================
DELETE FROM inbound_items WHERE TRUE;
DELETE FROM inbounds WHERE TRUE;
DELETE FROM outbound_items WHERE TRUE;
DELETE FROM outbounds WHERE TRUE;

-- ============================================================
-- 8. 발주 (Purchase Order) 전체
-- ============================================================
DELETE FROM purchase_order_shipment_items WHERE TRUE;
DELETE FROM purchase_order_shipments WHERE TRUE;
DELETE FROM purchase_order_items WHERE TRUE;
DELETE FROM purchase_orders WHERE TRUE;

-- ============================================================
-- 9. 품목 (Products)
-- ============================================================
DELETE FROM products WHERE TRUE;

-- ============================================================
-- 10. 카테고리 - 자식 먼저, 부모 나중에 삭제
-- ============================================================
-- 3레벨 (하위)
DELETE FROM categories WHERE level = 3;
-- 2레벨 (중간)
DELETE FROM categories WHERE level = 2;
-- 1레벨 (최상위)
DELETE FROM categories WHERE level = 1;

-- ============================================================
-- 11. 창고 / 센터 (웹에서 만들어진 데이터 포함)
-- ============================================================
DELETE FROM warehouses WHERE TRUE;
DELETE FROM centers WHERE TRUE;

-- ============================================================
-- 12. 공지사항
-- ============================================================
DELETE FROM notices WHERE TRUE;

-- ============================================================
-- 13. 감사 로그 (audit_logs)
-- ============================================================
DELETE FROM audit_logs WHERE TRUE;

-- ============================================================
-- 유지되는 데이터 (삭제하지 않음)
-- ============================================================
-- - users            : 관리자 계정 (로그인 필요)
-- - roles            : 권한 정의
-- - permissions      : 권한 항목 정의
-- - role_permissions : 권한 매핑
-- - reason_codes     : 입출고 사유 코드
