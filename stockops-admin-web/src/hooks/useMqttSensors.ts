/**
 * useMqttSensors – Sensimul MQTT WebSocket 실시간 센서 훅
 *
 * 브라우저에서 MQTT over WebSocket으로 Sensimul 브로커에 직접 연결하여
 * TEST_INDOOR_01 현장의 7개 센서 데이터를 실시간으로 수신합니다.
 *
 * 접속 정보:
 *   Host : sensormqtt.ithans.com
 *   Port : 9001 (WebSocket)
 *   Topic: sensimul/sites/TEST_INDOOR_01/sensors/+
 *   Auth : stockops / soldesk
 *
 * @author StockOps Team
 * @since 3.0
 */

import { useEffect, useRef, useState } from 'react'
import mqtt, { type MqttClient } from 'mqtt'

// ─── 상수 ────────────────────────────────────────────────────────────────────

const MQTT_BROKER_URL = 'wss://sensormqtt.ithans.com:9001'
const MQTT_USERNAME   = 'stockops'
const MQTT_PASSWORD   = 'soldesk'
const SITE_ID         = 'TEST_INDOOR_01'
const SUBSCRIBE_TOPIC = `sensimul/sites/${SITE_ID}/sensors/+`

// ─── 타입 ────────────────────────────────────────────────────────────────────

export type MqttConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error'

export interface SensorReading {
  /** 센서 ID (예: TEST_TEMP_01) */
  sensorId: string
  /** 현재 값 (숫자 또는 boolean 문자열) */
  value: number | string | null
  /** 수신 시각 */
  receivedAt: Date
  /** 원본 페이로드 문자열 */
  raw: string
}

export interface UseMqttSensorsResult {
  /** 연결 상태 */
  status: MqttConnectionStatus
  /** 센서 ID → 최신 reading 맵 */
  readings: Record<string, SensorReading>
  /** 마지막 에러 메시지 */
  error: string | null
  /** 수동 재연결 트리거 */
  reconnect: () => void
}

// ─── 센서 ID 목록 (사전 등록된 7개) ──────────────────────────────────────────

export const SENSIMUL_SENSORS = [
  { id: 'TEST_TEMP_01',     type: 'temperature',       label: '온도',       unit: '°C',     icon: '🌡️' },
  { id: 'TEST_HUM_01',      type: 'humidity',           label: '습도',       unit: '%',      icon: '💧' },
  { id: 'TEST_PM25_01',     type: 'pm25',               label: 'PM2.5',     unit: 'μg/m³',  icon: '🌫️' },
  { id: 'TEST_PM10_01',     type: 'pm10',               label: 'PM10',      unit: 'μg/m³',  icon: '🌫️' },
  { id: 'TEST_PRESSURE_01', type: 'pressure',           label: '기압',       unit: 'hPa',    icon: '🔵' },
  { id: 'TEST_DOOR_01',     type: 'door_open',          label: '문 열림',    unit: '',       icon: '🚪' },
  { id: 'TEST_PRESENCE_01', type: 'presence_detected',  label: '재실 감지',  unit: '',       icon: '👤' },
] as const

// ─── 페이로드 파싱 ────────────────────────────────────────────────────────────

/**
 * MQTT 페이로드를 파싱합니다.
 * Sensimul은 JSON 또는 단순 숫자/문자열을 발행합니다.
 * 예: { "value": 23.4 } 또는 "23.4" 또는 "true"
 */
function parsePayload(raw: string): number | string | null {
  try {
    const json = JSON.parse(raw) as unknown
    if (typeof json === 'object' && json !== null && 'value' in json) {
      return (json as { value: number | string }).value
    }
    if (typeof json === 'number' || typeof json === 'boolean') {
      return typeof json === 'boolean' ? String(json) : json
    }
    if (typeof json === 'string') {
      return isNaN(Number(json)) ? json : Number(json)
    }
    return raw
  } catch {
    // 단순 문자열이거나 숫자
    const num = Number(raw)
    return isNaN(num) ? raw : num
  }
}

// ─── 훅 ──────────────────────────────────────────────────────────────────────

export function useMqttSensors(): UseMqttSensorsResult {
  const [status, setStatus] = useState<MqttConnectionStatus>('connecting')
  const [readings, setReadings] = useState<Record<string, SensorReading>>({})
  const [error, setError] = useState<string | null>(null)
  const clientRef = useRef<MqttClient | null>(null)
  const reconnectCountRef = useRef(0)

  function connect() {
    // 이미 연결되어 있으면 종료
    if (clientRef.current) {
      clientRef.current.end(true)
      clientRef.current = null
    }

    setStatus('connecting')
    setError(null)

    const client = mqtt.connect(MQTT_BROKER_URL, {
      username: MQTT_USERNAME,
      password: MQTT_PASSWORD,
      clientId: `stockops-dashboard-${Math.random().toString(36).slice(2, 9)}`,
      reconnectPeriod: 0, // 자동 재연결 비활성화 (직접 제어)
      connectTimeout: 10000,
    })

    clientRef.current = client

    client.on('connect', () => {
      reconnectCountRef.current = 0
      setStatus('connected')
      setError(null)
      client.subscribe(SUBSCRIBE_TOPIC, { qos: 0 }, (err) => {
        if (err) {
          setError(`구독 실패: ${err.message}`)
        }
      })
    })

    client.on('message', (topic: string, message: Buffer) => {
      // 토픽에서 센서 ID 추출: sensimul/sites/{siteId}/sensors/{sensorId}
      const parts = topic.split('/')
      const sensorId = parts[parts.length - 1]
      if (!sensorId) return

      const raw = message.toString()
      const value = parsePayload(raw)

      setReadings((prev) => ({
        ...prev,
        [sensorId]: { sensorId, value, receivedAt: new Date(), raw },
      }))
    })

    client.on('error', (err: Error) => {
      setStatus('error')
      setError(`연결 오류: ${err.message}`)
    })

    client.on('offline', () => {
      setStatus('disconnected')
    })

    client.on('close', () => {
      if (status !== 'error') {
        setStatus('disconnected')
      }
    })
  }

  useEffect(() => {
    connect()
    return () => {
      clientRef.current?.end(true)
      clientRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return { status, readings, error, reconnect: connect }
}
