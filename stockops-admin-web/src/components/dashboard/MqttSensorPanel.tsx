/**
 * MqttSensorPanel – 대시보드용 실시간 MQTT 센서 현황 패널
 *
 * Sensimul TEST_INDOOR_01 현장의 7개 센서 데이터를 MQTT WebSocket으로
 * 실시간 수신하여 카드 그리드로 표시합니다.
 *
 * @author StockOps Team
 * @since 3.0
 */

import { useMemo } from 'react'
import { RefreshCw, Wifi, WifiOff, AlertCircle } from 'lucide-react'
import { SENSIMUL_SENSORS, useMqttSensors } from '@/hooks/useMqttSensors'
import type { MqttConnectionStatus } from '@/hooks/useMqttSensors'

// ─── 연결 상태 배지 ───────────────────────────────────────────────────────────

function ConnectionBadge({ status }: { status: MqttConnectionStatus }) {
  const config = {
    connecting: {
      icon: <RefreshCw className="w-3 h-3 animate-spin" />,
      label: '연결 중...',
      className: 'bg-amber-50 text-amber-600 border-amber-200',
    },
    connected: {
      icon: <Wifi className="w-3 h-3" />,
      label: '실시간 연결됨',
      className: 'bg-emerald-50 text-emerald-600 border-emerald-200',
    },
    disconnected: {
      icon: <WifiOff className="w-3 h-3" />,
      label: '연결 끊김',
      className: 'bg-neutral-100 text-neutral-500 border-neutral-200',
    },
    error: {
      icon: <AlertCircle className="w-3 h-3" />,
      label: '연결 오류',
      className: 'bg-red-50 text-red-600 border-red-200',
    },
  }

  const { icon, label, className } = config[status]

  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium ${className}`}>
      {icon}
      {label}
    </span>
  )
}

// ─── 센서 값 포맷 ─────────────────────────────────────────────────────────────

function formatSensorValue(
  value: number | string | null,
  type: string,
  unit: string,
): { display: string; statusClass: string } {
  if (value === null) {
    return { display: '–', statusClass: 'text-neutral-400' }
  }

  // boolean 계열 센서 (문 열림, 재실 감지)
  if (type === 'door_open') {
    const isOpen = value === true || value === 'true' || value === 1 || value === '1' || value === 'open'
    return {
      display: isOpen ? '열림' : '닫힘',
      statusClass: isOpen ? 'text-amber-500' : 'text-emerald-600',
    }
  }
  if (type === 'presence_detected') {
    const detected = value === true || value === 'true' || value === 1 || value === '1' || value === 'detected'
    return {
      display: detected ? '감지됨' : '없음',
      statusClass: detected ? 'text-blue-500' : 'text-neutral-400',
    }
  }

  // 수치 센서
  const num = typeof value === 'number' ? value : Number(value)
  if (isNaN(num)) {
    return { display: String(value), statusClass: 'text-neutral-600' }
  }

  const formatted = Number.isInteger(num) ? String(num) : num.toFixed(1)
  return { display: `${formatted}${unit ? ` ${unit}` : ''}`, statusClass: 'text-neutral-800' }
}

// ─── 시간 포맷 ────────────────────────────────────────────────────────────────

function formatRelativeTime(date: Date): string {
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
  if (seconds < 5) return '방금'
  if (seconds < 60) return `${seconds}초 전`
  return `${Math.floor(seconds / 60)}분 전`
}

// ─── 개별 센서 카드 ───────────────────────────────────────────────────────────

interface SensorCardProps {
  sensor: (typeof SENSIMUL_SENSORS)[number]
  value: number | string | null
  receivedAt: Date | null
  hasData: boolean
}

function SensorCard({ sensor, value, receivedAt, hasData }: SensorCardProps) {
  const { display, statusClass } = formatSensorValue(value, sensor.type, sensor.unit)

  return (
    <div className="relative flex flex-col gap-2 rounded-xl border border-neutral-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
      {/* 펄스 인디케이터 – 데이터 수신 중이면 표시 */}
      {hasData && (
        <span className="absolute right-3 top-3 flex h-2 w-2">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500" />
        </span>
      )}

      {/* 아이콘 + 라벨 */}
      <div className="flex items-center gap-2">
        <span className="text-xl" aria-hidden>{sensor.icon}</span>
        <span className="text-xs font-medium text-text-secondary">{sensor.label}</span>
      </div>

      {/* 값 */}
      <p className={`text-2xl font-bold leading-none ${statusClass}`}>
        {display}
      </p>

      {/* 센서 ID + 마지막 수신 시각 */}
      <div className="mt-auto pt-1 border-t border-neutral-100">
        <p className="text-[10px] text-text-light font-mono">{sensor.id}</p>
        {receivedAt && (
          <p className="text-[10px] text-text-light mt-0.5">
            {formatRelativeTime(receivedAt)}
          </p>
        )}
        {!hasData && (
          <p className="text-[10px] text-neutral-400 mt-0.5">대기 중...</p>
        )}
      </div>
    </div>
  )
}

// ─── 패널 ─────────────────────────────────────────────────────────────────────

export function MqttSensorPanel() {
  const { status, readings, error, reconnect } = useMqttSensors()

  // 각 센서별로 최신 데이터 추출
  const sensorCards = useMemo(
    () =>
      SENSIMUL_SENSORS.map((sensor) => {
        const reading = readings[sensor.id]
        return {
          sensor,
          value: reading?.value ?? null,
          receivedAt: reading?.receivedAt ?? null,
          hasData: !!reading,
        }
      }),
    [readings],
  )

  const receivedCount = Object.keys(readings).length

  return (
    <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-5">
        <div>
          <h2 className="text-lg font-semibold text-text-primary flex items-center gap-2">
            🔌 실시간 센서 현황
            <ConnectionBadge status={status} />
          </h2>
          <p className="text-xs text-text-secondary mt-0.5">
            TEST_INDOOR_01 · sensormqtt.ithans.com · 5초 주기
            {status === 'connected' && receivedCount > 0 && (
              <span className="ml-2 text-emerald-600 font-medium">
                {receivedCount}/{SENSIMUL_SENSORS.length}개 수신됨
              </span>
            )}
          </p>
        </div>
        {(status === 'error' || status === 'disconnected') && (
          <button
            type="button"
            onClick={reconnect}
            className="flex items-center gap-2 rounded-lg border border-neutral-200 bg-neutral-50 px-3 py-1.5 text-sm text-text-secondary hover:bg-neutral-100 transition-colors"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            재연결
          </button>
        )}
      </div>

      {/* 에러 메시지 */}
      {error && (
        <div className="mb-4 flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
          <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* 센서 카드 그리드 */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-7 gap-3">
        {sensorCards.map(({ sensor, value, receivedAt, hasData }) => (
          <SensorCard
            key={sensor.id}
            sensor={sensor}
            value={value}
            receivedAt={receivedAt}
            hasData={hasData}
          />
        ))}
      </div>

      {/* 연결 중 스켈레톤 */}
      {status === 'connecting' && receivedCount === 0 && (
        <div className="mt-3 text-center text-xs text-text-light animate-pulse">
          MQTT 브로커에 연결하는 중입니다...
        </div>
      )}
    </div>
  )
}
