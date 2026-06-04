# StockOps EKS 배포 가이드

## 전체 아키텍처

```
인터넷 트래픽
      │
      ▼
┌─────────────────────────────────────────┐
│         AWS ALB (Ingress)               │
│  /api/* → stockops-api:8080            │
│  /ai/*  → stockops-ai:8000             │
│  /admin → stockops-admin-web:80        │
│  /      → stockops-client-web:80       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│      EKS Cluster (ap-northeast-2)       │
│  Namespace: stockops                    │
│                                         │
│  ┌──────────┐  ┌──────────┐            │
│  │ API Pod  │  │  AI Pod  │            │
│  │ (x2~5)  │  │  (x1~3)  │            │
│  └──────────┘  └──────────┘            │
│  ┌──────────┐  ┌──────────┐            │
│  │Client Pod│  │Admin Pod │            │
│  │  (x2)   │  │  (x1)   │            │
│  └──────────┘  └──────────┘            │
│                                         │
│  Node Group: t3.medium × 2~4           │
└────────┬────────────────────────────────┘
         │
         ├──→ RDS PostgreSQL (db.t3.micro)
         ├──→ ElastiCache Redis (cache.t3.micro)
         └──→ AWS Secrets Manager (시크릿 관리)
```

## 사용된 AWS 서비스

| 서비스 | 용도 |
|--------|------|
| **EKS** | Kubernetes 클러스터 (컨트롤 플레인) |
| **EC2 (t3.medium)** | 워커 노드 (2~4개, Auto Scaling) |
| **ECR** | Docker 이미지 레지스트리 (4개 리포) |
| **ALB** | L7 로드밸런서 (AWS Load Balancer Controller) |
| **RDS PostgreSQL** | 운영 데이터베이스 |
| **ElastiCache Redis** | 캐시 / Rate Limiting (Bucket4j) |
| **AWS Secrets Manager** | DB 비밀번호, JWT 시크릿 등 관리 |
| **External Secrets Operator** | Secrets Manager → K8s Secret 동기화 |
| **CloudWatch Container Insights** | 컨테이너 로그 및 메트릭 수집 |
| **IAM IRSA** | Pod 단위 AWS 권한 제어 |
| **ACM** | SSL/TLS 인증서 (도메인 있을 경우) |

## 디렉터리 구조

```
k8s/
├── namespace.yaml                        # stockops 네임스페이스
├── configmaps/
│   ├── api-config.yaml                   # Spring Boot 비-민감 환경변수
│   └── ai-config.yaml                    # FastAPI 비-민감 환경변수
├── external-secrets/
│   ├── cluster-secret-store.yaml         # AWS Secrets Manager 연결
│   ├── api-external-secret.yaml          # stockops/prod/api → K8s Secret
│   └── ai-external-secret.yaml           # stockops/prod/ai  → K8s Secret
├── api/
│   ├── deployment.yaml                   # Spring Boot (2~5 replicas, HPA)
│   ├── service.yaml                      # ClusterIP :8080
│   ├── hpa.yaml                          # CPU 60% / Mem 75% 기준 스케일링
│   └── serviceaccount.yaml               # IRSA
├── ai/
│   ├── deployment.yaml                   # FastAPI (1~3 replicas, HPA)
│   ├── service.yaml                      # ClusterIP :8000
│   └── hpa.yaml                          # CPU 70% / Mem 80% 기준 스케일링
├── client-web/
│   ├── deployment.yaml                   # React Nginx (2 replicas)
│   └── service.yaml                      # ClusterIP :80
├── admin-web/
│   ├── deployment.yaml                   # React Nginx (1 replica)
│   └── service.yaml                      # ClusterIP :80
├── ingress/
│   └── ingress.yaml                      # AWS ALB Ingress (경로 기반 라우팅)
└── scripts/
    └── setup-eks.sh                      # 전체 자동화 설정 스크립트
```

## 빠른 시작

### 사전 준비

```bash
# 필수 도구 설치 확인
aws --version        # AWS CLI v2
eksctl version       # eksctl 0.180+
kubectl version      # kubectl 1.29+
helm version         # Helm 3.14+
```

### 1단계: AWS Secrets Manager 시크릿 설정

```bash
# API 서버 시크릿 (실제 값으로 교체)
aws secretsmanager update-secret \
  --secret-id stockops/prod/api \
  --region ap-northeast-2 \
  --secret-string '{
    "DB_HOST": "stockops-db.xxxxxxxx.ap-northeast-2.rds.amazonaws.com",
    "DB_USER": "stockops",
    "DB_PASSWORD": "매우_강력한_비밀번호",
    "JWT_SECRET": "최소_32자_이상의_안전한_JWT_시크릿_키_값",
    "SPRING_DATA_REDIS_HOST": "stockops-redis.xxxxxx.ng.0001.apn2.cache.amazonaws.com",
    "SPRING_MAIL_HOST": "email-smtp.ap-northeast-2.amazonaws.com",
    "SPRING_MAIL_USERNAME": "AKIAXXXXXXXXXXXXXXXX",
    "SPRING_MAIL_PASSWORD": "SES_SMTP_비밀번호"
  }'

# AI 모듈 시크릿
aws secretsmanager update-secret \
  --secret-id stockops/prod/ai \
  --region ap-northeast-2 \
  --secret-string '{
    "DATABASE_URL": "postgresql://stockops:비밀번호@RDS_ENDPOINT:5432/stockops",
    "AI_MODULE_API_KEY": "AI_API_키"
  }'
```

### 2단계: 자동화 스크립트 실행

```bash
# Linux/Mac
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
chmod +x k8s/scripts/setup-eks.sh
./k8s/scripts/setup-eks.sh
```

> **Windows (PowerShell)**: WSL2 또는 Git Bash에서 실행하거나 AWS CloudShell 사용 권장

### 3단계: 배포 상태 확인

```bash
# 네임스페이스 내 모든 Pod 확인
kubectl get pods -n stockops

# Ingress ALB DNS 주소 확인 (약 2~3분 후 할당)
kubectl get ingress -n stockops

# API 헬스체크
ALB_DNS=$(kubectl get ingress stockops-ingress -n stockops \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://${ALB_DNS}/api/actuator/health
```

## CI/CD 파이프라인 설정

GitLab CI/CD Variables에 다음을 설정하세요:

| 변수명 | 설명 | 마스킹 |
|--------|------|--------|
| `AWS_ACCOUNT_ID` | AWS 계정 ID (12자리) | ✅ |
| `AWS_ACCESS_KEY_ID` | IAM 사용자 액세스 키 | ✅ |
| `AWS_SECRET_ACCESS_KEY` | IAM 사용자 시크릿 키 | ✅ |
| `STOCKOPS_DOMAIN` | 도메인 (없으면 ALB DNS) | ❌ |

> **권장**: 장기적으로 `AWS_ACCESS_KEY_ID` 대신 **GitLab OIDC + IAM Role** 방식으로 전환

## 운영 팁

### Pod 로그 확인 (CloudWatch 대신 로컬)
```bash
kubectl logs -f deployment/stockops-api -n stockops
kubectl logs -f deployment/stockops-ai  -n stockops
```

### HPA 스케일링 상태 확인
```bash
kubectl get hpa -n stockops
```

### Secrets Manager 시크릿 변경 후 Pod 재시작
```bash
# ExternalSecret이 1시간마다 자동 갱신되지만, 즉시 적용하려면:
kubectl rollout restart deployment/stockops-api -n stockops
```

### 이미지 수동 배포 (긴급 패치)
```bash
ECR="123456789012.dkr.ecr.ap-northeast-2.amazonaws.com"
kubectl set image deployment/stockops-api \
  stockops-api=${ECR}/stockops-api:새태그 \
  -n stockops
```

## 월 예상 비용 (ap-northeast-2)

| 서비스 | 사양 | 월 비용 |
|--------|------|---------|
| EKS Control Plane | — | $73 |
| EC2 t3.medium × 2 | 워커 노드 | ~$65 |
| RDS db.t3.micro | PostgreSQL | ~$15 |
| ElastiCache cache.t3.micro | Redis | ~$12 |
| ALB | Ingress | ~$16 |
| ECR | 이미지 저장 | ~$1 |
| CloudWatch | 로그/메트릭 | ~$5 |
| Secrets Manager | 4개 시크릿 | ~$1 |
| **합계** | | **~$188/월** |
