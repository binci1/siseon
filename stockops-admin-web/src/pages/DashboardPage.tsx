/**
 * Dashboard page component.
 * Main landing page after login showing system overview.
 * Redesigned to match web_proto with stats cards, alerts, AI widget,
 * and refresh metadata for live dashboard monitoring.
 *
 * @author StockOps Team
 * @since 1.0
 */

import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { useAuthStore } from '@/stores/authStore'
import { useDashboardSummary, useDashboardTransactions } from '@/hooks/useDashboard'
import { useEnvironmentDashboard } from '@/hooks/useEnvironment'
import { createProduct } from '@/api/products'
import { ProductModal } from '@/components/products/ProductModal'
import { CreateInboundModal } from '@/components/inbound/CreateInboundModal'
import { CreateOutboundModal } from '@/components/outbound/CreateOutboundModal'
import { StatCard } from '@/components/ui/StatCard'
import { AlertItem } from '@/components/ui/AlertItem'
import { ActivityItem } from '@/components/ui/ActivityItem'
import { AIBanner } from '@/components/ui/AIBanner'
import { AlertTriangle, ArrowDownToLine, ArrowUpFromLine, Package, RefreshCw, Wifi, WifiOff } from 'lucide-react'
import type { CreateProductRequest, UpdateProductRequest } from '@/types/product'
import { SENSIMUL_SENSORS, useMqttSensors } from '@/hooks/useMqttSensors'
import type { MqttConnectionStatus } from '@/hooks/useMqttSensors'

/**
 * Dashboard page displaying welcome message and system overview.
 * Shows key metrics, recent transactions, quick actions, and dashboard
 * refresh status with manual refetch support.
 *
 * @returns Dashboard page JSX element
 */
export function DashboardPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const queryClient = useQueryClient()
  const [now, setNow] = useState(() => Date.now())
  const [isManualRefreshing, setIsManualRefreshing] = useState(false)
  const [quickAction, setQuickAction] = useState<'inbound' | 'outbound' | 'product' | null>(null)
  const [isProductSubmitting, setIsProductSubmitting] = useState(false)
  const {
    data: summary,
    refetch: refetchSummary,
    dataUpdatedAt: summaryUpdatedAt,
  } = useDashboardSummary()
  const {
    data: transactions,
    refetch: refetchTransactions,
    dataUpdatedAt: transactionsUpdatedAt,
  } = useDashboardTransactions(5)
  const environmentDashboardQuery = useEnvironmentDashboard()

  useEffect(() => {
    const intervalId = window.setInterval(() => {
      setNow(Date.now())
    }, 1000)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [])

  const lastUpdatedAt = useMemo(() => {
    return Math.max(summaryUpdatedAt, transactionsUpdatedAt, environmentDashboardQuery.dataUpdatedAt)
  }, [summaryUpdatedAt, transactionsUpdatedAt, environmentDashboardQuery.dataUpdatedAt])

  const lastUpdatedText = useMemo(() => {
    if (!lastUpdatedAt) {
      return '마지막 갱신: 데이터 대기 중'
    }

    const secondsAgo = Math.max(0, Math.floor((now - lastUpdatedAt) / 1000))
    return `마지막 갱신: ${secondsAgo}초 전`
  }, [lastUpdatedAt, now])

  async function handleManualRefresh(): Promise<void> {
    setIsManualRefreshing(true)

    try {
      await Promise.all([
        refetchSummary(),
        refetchTransactions(),
        queryClient.invalidateQueries({ queryKey: ['environment', 'dashboard'] }),
      ])
    }
    finally {
      setIsManualRefreshing(false)
      setNow(Date.now())
    }
  }

  const hasEnvironmentAlert =
    (environmentDashboardQuery.data?.warningCount ?? 0) > 0 ||
    (environmentDashboardQuery.data?.dangerCount ?? 0) > 0

  const environmentVariant = environmentDashboardQuery.isLoading
    ? 'default'
    : (environmentDashboardQuery.data?.dangerCount ?? 0) > 0
      ? 'danger'
      : (environmentDashboardQuery.data?.warningCount ?? 0) > 0
        ? 'warning'
        : 'success'

  const canShowAiRecommendation =
    (summary?.totalProducts ?? 0) > 0 &&
    (summary?.recentTransactionCount ?? 0) > 0

  const aiDescription = canShowAiRecommendation
    ? '최근 입출고 이력과 안전재고 기준으로 발주 후보를 검토하세요. 상세 화면에서 모델 근거와 추천 수량을 확인할 수 있습니다.'
    : '추천을 만들 만큼 입출고 이력이 충분하지 않습니다. 상품, 입고, 출고 데이터가 쌓이면 자동 발주 후보를 표시합니다.'

  async function handleProductSubmit(data: CreateProductRequest | UpdateProductRequest): Promise<void> {
    setIsProductSubmitting(true)

    try {
      await createProduct(data as CreateProductRequest)
      await queryClient.invalidateQueries({ queryKey: ['products'] })
      setQuickAction(null)
    }
    finally {
      setIsProductSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">대시보드</h1>
          <p className="text-text-secondary mt-1">
            안녕하세요, <span className="font-medium">{user?.name || '관리자'}</span>님!
            현재 시스템 현황을 확인하세요.
          </p>
          <p className="text-sm text-text-secondary mt-2">{lastUpdatedText}</p>
        </div>
        <button
          type="button"
          onClick={handleManualRefresh}
          disabled={isManualRefreshing}
          className="flex items-center justify-center gap-2 px-4 py-2 min-h-[44px] bg-white border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors disabled:cursor-not-allowed disabled:opacity-70"
        >
          <RefreshCw className={`w-4 h-4 ${isManualRefreshing ? 'animate-spin' : ''}`} />
          {isManualRefreshing ? '새로고침 중...' : '새로고침'}
        </button>
      </div>

      {/* Stats Grid – 상단 3개 카드 + 하단 환경 상태(MQTT) 전체 너비 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Link to="/products" className="block rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500">
          <StatCard
            icon="📦"
            label="전체 품목"
            value={summary?.totalProducts ?? 0}
            variant="default"
          />
        </Link>
        <Link to="/expiry" className="block rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500">
          <StatCard
            icon="⚠️"
            label="유통기한 임박"
            value={summary?.criticalExpiryCount ?? 0}
            change="3일 이내"
            variant="warning"
          />
        </Link>
        <Link to="/inbound" className="block rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500">
          <StatCard
            icon="📊"
            label="오늘 입출고"
            value={`${summary?.todayInboundCount ?? 0} / ${summary?.todayOutboundCount ?? 0}`}
            change="입고 / 출고"
            variant="default"
          />
        </Link>

        {/* 환경 상태 – 전체 너비, MQTT 실시간 센서 */}
        <div className="md:col-span-3">
          <EnvironmentSensorCard />
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-neutral-200">
        <h2 className="text-lg font-semibold mb-4 text-text-primary">빠른 작업</h2>
        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            onClick={() => setQuickAction('inbound')}
            className="flex items-center justify-center gap-2 px-5 py-2.5 min-h-[44px] bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
          >
            <ArrowDownToLine className="w-5 h-5" />
            입고 등록
          </button>
          <button
            type="button"
            onClick={() => setQuickAction('outbound')}
            className="flex items-center justify-center gap-2 px-5 py-2.5 min-h-[44px] bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
          >
            <ArrowUpFromLine className="w-5 h-5" />
            출고 등록
          </button>
          <button
            type="button"
            onClick={() => setQuickAction('product')}
            className="flex items-center justify-center gap-2 px-5 py-2.5 min-h-[44px] bg-neutral-100 text-text-primary border border-neutral-200 rounded-lg hover:bg-neutral-200 transition-colors font-medium"
          >
            <Package className="w-5 h-5" />
            상품 등록
          </button>
        </div>
      </div>

      {/* Alerts Section */}
      {(summary?.criticalExpiryCount ?? 0) > 0 && (
        <div className="bg-white p-6 rounded-xl shadow-sm border border-neutral-200">
          <h2 className="text-lg font-semibold mb-4 text-text-primary">⚠️ 주요 알림</h2>
          <div className="space-y-3">
            <AlertItem
              type="danger"
              icon="🔥"
              title="유통기한 임박"
              message={`${summary?.criticalExpiryCount}개 품목이 3일 이내에 만료됩니다`}
              timestamp="5분 전"
              actionLabel="확인하기"
              onAction={() => {}}
            />
            {summary?.lowStockCount && summary.lowStockCount > 0 && (
              <AlertItem
                type="warning"
                icon="📉"
                title="재고 부족"
                message={`${summary.lowStockCount}개 품목의 재고가 안전재고 이하입니다`}
                timestamp="1시간 전"
                actionLabel="확인하기"
                onAction={() => {}}
              />
            )}
          </div>
        </div>
      )}

      {/* AI Banner */}
      <AIBanner
        title="AI 추천"
        description={aiDescription}
        actionLabel={canShowAiRecommendation ? '추천 검토' : undefined}
        onAction={() => navigate('/ai')}
      />

      {/* Recent Activity */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-neutral-200">
        <h2 className="text-lg font-semibold mb-4 text-text-primary">최근 활동</h2>
        {transactions && transactions.length > 0 ? (
          <div className="space-y-2">
            {transactions.slice(0, 5).map((tx) => (
              <ActivityItem
                key={tx.id}
                time={new Date(tx.createdAt).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })}
                type={tx.type === 'INBOUND' ? 'inbound' : tx.type === 'OUTBOUND' ? 'outbound' : 'adjust'}
                description={`${tx.productName} - ${tx.type === 'INBOUND' ? '+' : '-'}${tx.quantity}개`}
                user={tx.createdBy?.toString() || '시스템'}
              />
            ))}
          </div>
        ) : (
          <p className="text-text-secondary text-center py-8">최근 활동이 없습니다</p>
        )}
      </div>

      {quickAction === 'inbound' && (
        <CreateInboundModal onClose={() => setQuickAction(null)} />
      )}

      {quickAction === 'outbound' && (
        <CreateOutboundModal
          onClose={() => setQuickAction(null)}
          onSuccess={() => {
            setQuickAction(null)
            queryClient.invalidateQueries({ queryKey: ['outbounds'] })
          }}
        />
      )}

      <ProductModal
        isOpen={quickAction === 'product'}
        onClose={() => setQuickAction(null)}
        onSubmit={handleProductSubmit}
        isLoading={isProductSubmitting}
      />
    </div>
  )
}

// ─── 환경 상태 카드 (MQTT 실시간) ────────────────────────────────────────────

function formatValue(value: number | string | null, type: string, unit: string): { display: string; cls: string } {
  if (value === null) return { display: '–', cls: 'text-neutral-400' }
  if (type === 'door_open') {
    const open = value === true || value === 'true' || value === 1 || value === '1' || value === 'open'
    return { display: open ? '열림' : '닫힘', cls: open ? 'text-amber-500 font-semibold' : 'text-emerald-600' }
  }
  if (type === 'presence_detected') {
    const yes = value === true || value === 'true' || value === 1 || value === '1' || value === 'detected'
    return { display: yes ? '감지됨' : '없음', cls: yes ? 'text-blue-500 font-semibold' : 'text-neutral-400' }
  }
  const num = Number(value)
  if (isNaN(num)) return { display: String(value), cls: 'text-neutral-700' }
  return { display: `${Number.isInteger(num) ? num : num.toFixed(1)}${unit ? ' ' + unit : ''}`, cls: 'text-neutral-800' }
}

function StatusDot({ status }: { status: MqttConnectionStatus }) {
  const map: Record<MqttConnectionStatus, { color: string; label: string }> = {
    connecting:   { color: 'bg-amber-400 animate-pulse', label: '연결 중' },
    connected:    { color: 'bg-emerald-500',             label: '실시간' },
    disconnected: { color: 'bg-neutral-400',             label: '연결 끊김' },
    error:        { color: 'bg-red-500',                 label: '오류' },
  }
  const { color, label } = map[status]
  return (
    <span className="inline-flex items-center gap-1.5 text-xs text-text-secondary">
      <span className={`inline-block h-2 w-2 rounded-full ${color}`} />
      {label}
    </span>
  )
}

function EnvironmentSensorCard() {
  const { status, readings, error, reconnect } = useMqttSensors()
  const receivedCount = Object.keys(readings).length

  return (
    <Link
      to="/environment"
      className="block rounded-xl border border-neutral-200 bg-white shadow-sm hover:shadow-md transition-shadow focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      {/* 헤더 */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 border-b border-neutral-100">
        <div className="flex items-center gap-2">
          <span className="text-xl">🌡️</span>
          <span className="text-sm font-semibold text-text-primary">환경 상태</span>
          <StatusDot status={status} />
          {status === 'connected' && receivedCount > 0 && (
            <span className="text-xs text-emerald-600 font-medium">
              {receivedCount}/{SENSIMUL_SENSORS.length}개 수신
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          {status === 'connected'
            ? <Wifi className="w-4 h-4 text-emerald-500" />
            : <WifiOff className="w-4 h-4 text-neutral-400" />}
          {(status === 'error' || status === 'disconnected') && (
            <button
              type="button"
              onClick={(e) => { e.preventDefault(); reconnect() }}
              className="text-xs text-primary-600 hover:underline"
            >
              재연결
            </button>
          )}
        </div>
      </div>

      {/* 오류 메시지 */}
      {error && (
        <p className="px-5 py-2 text-xs text-red-500">{error}</p>
      )}

      {/* 센서 카드 그리드 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-0 divide-x divide-y divide-neutral-100">
        {SENSIMUL_SENSORS.map((sensor) => {
          const reading = readings[sensor.id]
          const { display, cls } = formatValue(reading?.value ?? null, sensor.type, sensor.unit)
          const hasData = !!reading

          return (
            <div key={sensor.id} className="relative flex flex-col gap-1 px-4 py-3">
              {/* 수신 중 펄스 */}
              {hasData && (
                <span className="absolute right-2 top-2 flex h-1.5 w-1.5">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                  <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-emerald-500" />
                </span>
              )}
              <span className="text-base">{sensor.icon}</span>
              <span className="text-[11px] text-text-secondary">{sensor.label}</span>
              <span className={`text-lg font-bold leading-tight ${cls}`}>{display}</span>
              {reading?.receivedAt && (
                <span className="text-[10px] text-text-light mt-auto">
                  {Math.floor((Date.now() - reading.receivedAt.getTime()) / 1000)}초 전
                </span>
              )}
              {!hasData && (
                <span className="text-[10px] text-neutral-400">대기 중</span>
              )}
            </div>
          )
        })}
      </div>
    </Link>
  )
}
