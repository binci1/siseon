# Sensimul 테스트 현장 및 MQTT 접속 정보

## 서버 정보

- 서버: `sensormqtt.ithans.com`
- Sensimul Web: `https://sensimul.ithans.com`
- Sensimul MQTT Broker: `sensormqtt.ithans.com:1883`
- Sensimul MQTT WebSocket: `sensormqtt.ithans.com:9001`

## 외부 MQTT 연동 입력값

## 테스트 현장

- 현장 ID: `TEST_INDOOR_01`
- 현장명: `Test Indoor Site 01`
- 현장 유형: `indoor`
- 시뮬레이션 상태: 정상 실행 확인
- 실행 로그 확인 내용:
  - MQTT 연결 성공: `tcp://mqtt:1883`
  - 시뮬레이션 대상 현장: `TEST_INDOOR_01`
  - 센서 수: `7`
  - 조절기 수: `6`
  - Tick interval: `5s`

## 센서 리스트

| 센서 ID | 센서 유형 | 설명 |
|---|---|---|
| `TEST_TEMP_01` | `temperature` | 온도 |
| `TEST_HUM_01` | `humidity` | 습도 |
| `TEST_PM25_01` | `pm25` | PM2.5 |
| `TEST_PM10_01` | `pm10` | PM10 |
| `TEST_PRESSURE_01` | `pressure` | 기압 |
| `TEST_DOOR_01` | `door_open` | 문 열림 여부 |
| `TEST_PRESENCE_01` | `presence_detected` | 재실 감지 여부 |

## 조절기 리스트

| 조절기 ID | 조절기 유형 | 상태 |
|---|---|---|
| `TEST_COOLING_01` | `cooling` | `off` |
| `TEST_HEATING_01` | `heating` | `off` |
| `TEST_HUMIDIFYING_01` | `humidifying` | `off` |
| `TEST_DEHUMIDIFYING_01` | `dehumidifying` | `off` |
| `TEST_VENTILATION_01` | `ventilation` | `off` |
| `TEST_AIR_PURIFIER_01` | `air_purifier` | `off` |

## MQTT Subscribe 정보

전체 센서 데이터를 한 번에 구독할 때:

```bash
mosquitto_sub -h 192.168.0.11 -p 1883 -t 'sensimul/sites/TEST_INDOOR_01/sensors/+' -v
```

개별 센서 토픽:

```text
sensimul/sites/TEST_INDOOR_01/sensors/TEST_TEMP_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_HUM_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_PM25_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_PM10_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_PRESSURE_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_DOOR_01
sensimul/sites/TEST_INDOOR_01/sensors/TEST_PRESENCE_01
```

## MQTT 메시지 예시

발행 토픽 구조:

```text
sensimul/sites/{site_id}/sensors/{sensor_id}
```

테스트 현장의 실제 토픽 구조:

```text
sensimul/sites/TEST_INDOOR_01/sensors/{sensor_id}
```

외부 클라이언트에서는 MQTT WebSocket 주소 `sensormqtt.ithans.com`, 포트 `9001`로 접속한다.

인증 정보:

```text
Username: stockops
Password: soldesk
```

내부 TCP MQTT 테스트가 필요할 때는 서버 IP `192.168.0.11`, 포트 `1883`을 사용할 수 있다.

## Web 접속

브라우저에서 아래 주소로 접속한다.

```text
https://sensimul.ithans.com
```

## 작업 결과 요약

- `TEST_INDOOR_01` 실내 테스트 현장 생성 완료
- 내장 센서 유형 7종 각각 1개씩 생성 완료
- 내장 조절기 유형 6종 각각 1개씩 생성 완료
- `sensimul-app` 재기동 완료
- MQTT 발행 대상이 `TEST_INDOOR_01`로 설정된 것을 로그로 확인
