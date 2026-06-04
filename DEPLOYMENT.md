# StockOps 배포 가이드

> 이 문서는 **StockOps 시스템을 새 AWS 환경에 처음부터 배포**하는 전 과정을 순서대로 설명합니다.
> AWS·Docker·Kubernetes를 처음 다루는 분도 따라할 수 있도록 작성했습니다.

---

## 시스템 구성 요약

| 컴포넌트 | 역할 | 기술 |
|---|---|---|
| `stockops-api-server` | 백엔드 REST API | Spring Boot 3, Java 21 |
| `stockops-ai-module` | AI 재고 예측 서비스 | Python FastAPI, Prophet |
| `stockops-admin-web` | 관리자 대시보드 | React + Vite, Nginx |
| `stockops-client-web` | 클라이언트 발주 포털 | React + Vite, Nginx |

**외부 서비스 연동**
- MQTT: `sensormqtt.ithans.com:9001` (실시간 창고 환경 센서, WebSocket)
- 데이터베이스: AWS RDS PostgreSQL
- 캐시: AWS ElastiCache Redis
- 이미지 저장소: AWS ECR

**접근 경로 (ALB 기준)**

| URL 경로 | 연결 대상 |
|---|---|
| `http://ALB주소/` | 클라이언트 웹 |
| `http://ALB주소/admin` | 관리자 웹 |
| `http://ALB주소/api` | API 서버 |
| `http://ALB주소/ai` | AI 모듈 |

---

## 1단계: 로컬 도구 설치

모든 작업은 **Linux/Mac 터미널** 또는 **Windows WSL2/Git Bash**에서 실행합니다.

### 필수 도구

```bash
# 1. AWS CLI v2
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
aws --version   # aws-cli/2.x.x 확인

# 2. eksctl (EKS 클러스터 관리)
# https://eksctl.io/installation/
eksctl version  # 0.180+ 확인

# 3. kubectl (Kubernetes 명령줄)
kubectl version --client  # v1.29+ 확인

# 4. Helm (Kubernetes 패키지 관리)
helm version    # v3.14+ 확인

# 5. Docker Desktop
docker --version   # 24.x+ 확인
```

### AWS CLI 로그인

```bash
aws configure
# AWS Access Key ID:     [IAM 사용자 키]
# AWS Secret Access Key: [IAM 사용자 시크릿]
# Default region name:   ap-northeast-2
# Default output format: json
```

> **IAM 필요 권한**: `AmazonEKSFullAccess`, `AmazonEC2ContainerRegistryFullAccess`,
> `AmazonRDSFullAccess`, `ElastiCacheFullAccess`, `SecretsManagerFullAccess`,
> `IAMFullAccess`

---

## 2단계: AWS 계정 ID 확인

이후 모든 단계에서 계정 ID가 반복 사용됩니다. 터미널에서 실행 후 값을 메모해두세요.

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=ap-northeast-2

echo "계정 ID: $AWS_ACCOUNT_ID"
echo "리전:    $AWS_REGION"
```

---

## 3단계: ECR 리포지터리 생성

Docker 이미지를 저장할 저장소를 4개 만듭니다.

```bash
for repo in stockops-api stockops-ai stockops-client-web stockops-admin-web; do
  aws ecr create-repository \
    --repository-name "$repo" \
    --region "$AWS_REGION" \
    --image-scanning-configuration scanOnPush=true \
    --tags Key=Project,Value=stockops 2>/dev/null \
    && echo "생성완료: $repo" \
    || echo "이미존재: $repo"
done
```

---

## 4단계: Docker 이미지 빌드 & ECR 푸시

### ECR 로그인

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS \
    --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

### 각 서비스 빌드 & 푸시

프로젝트 루트(`stockops/` 폴더)에서 실행합니다.

```bash
ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# ① API 서버 (Spring Boot, 빌드 약 3~5분)
docker build -t $ECR/stockops-api:latest ./stockops-api-server
docker push $ECR/stockops-api:latest

# ② AI 모듈 (FastAPI)
docker build -t $ECR/stockops-ai:latest ./stockops-ai-module
docker push $ECR/stockops-ai:latest

# ③ 관리자 웹
docker build -t $ECR/stockops-admin-web:latest ./stockops-admin-web
docker push $ECR/stockops-admin-web:latest

# ④ 클라이언트 웹
docker build -t $ECR/stockops-client-web:latest ./stockops-client-web
docker push $ECR/stockops-client-web:latest
```

---

## 5단계: RDS PostgreSQL 생성

> AWS 콘솔에서 생성할 경우: RDS → 데이터베이스 생성 → PostgreSQL → Free tier (테스트) 또는 db.t3.micro (운영)

CLI 예시:

```bash
aws rds create-db-instance \
  --db-instance-identifier stockops-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.3 \
  --master-username stockops \
  --master-user-password "변경필수_강력한비밀번호" \
  --db-name stockops \
  --allocated-storage 20 \
  --storage-type gp3 \
  --no-publicly-accessible \
  --tags Key=Project,Value=stockops
```

생성 완료 후 **엔드포인트 주소**를 메모하세요.
예: `stockops-db.xxxxxxxx.ap-northeast-2.rds.amazonaws.com`

---

## 6단계: ElastiCache Redis 생성

```bash
aws elasticache create-replication-group \
  --replication-group-id stockops-redis \
  --description "StockOps Redis cache" \
  --num-cache-clusters 1 \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --tags Key=Project,Value=stockops
```

생성 완료 후 **Primary Endpoint 주소**를 메모하세요.
예: `stockops-redis.xxxxxx.ng.0001.apn2.cache.amazonaws.com`

---

## 7단계: AWS Secrets Manager 시크릿 설정

**반드시** 5단계·6단계에서 확인한 실제 값으로 채워서 입력합니다.

```bash
# API 서버 시크릿
aws secretsmanager create-secret \
  --name stockops/prod/api \
  --region "$AWS_REGION" \
  --secret-string '{
    "DB_HOST":                  "stockops-db.xxxxxxxx.ap-northeast-2.rds.amazonaws.com",
    "DB_USER":                  "stockops",
    "DB_PASSWORD":              "강력한_DB_비밀번호",
    "JWT_SECRET":               "최소_32자_이상의_랜덤_문자열_abcdef1234567890xyz",
    "SPRING_DATA_REDIS_HOST":   "stockops-redis.xxxxxx.ng.0001.apn2.cache.amazonaws.com",
    "SPRING_MAIL_HOST":         "email-smtp.ap-northeast-2.amazonaws.com",
    "SPRING_MAIL_USERNAME":     "AWS_SES_SMTP_사용자명",
    "SPRING_MAIL_PASSWORD":     "AWS_SES_SMTP_비밀번호"
  }'

# AI 모듈 시크릿
aws secretsmanager create-secret \
  --name stockops/prod/ai \
  --region "$AWS_REGION" \
  --secret-string '{
    "DATABASE_URL":     "postgresql://stockops:비밀번호@RDS엔드포인트:5432/stockops",
    "AI_MODULE_API_KEY": "필요시_AI_API_키"
  }'
```

> 이미 시크릿이 존재한다면 `create-secret` 대신 `update-secret --secret-id stockops/prod/api`을 사용합니다.

---

## 8단계: EKS 클러스터 생성 (약 15~20분 소요)

```bash
eksctl create cluster \
  --name stockops-cluster \
  --region "$AWS_REGION" \
  --nodegroup-name stockops-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --managed \
  --with-oidc \
  --alb-ingress-access \
  --full-ecr-access

# kubeconfig 업데이트 (kubectl이 이 클러스터를 사용하도록)
aws eks update-kubeconfig --region "$AWS_REGION" --name stockops-cluster

# 노드 확인 (STATUS: Ready 여야 함)
kubectl get nodes
```

---

## 9단계: AWS Load Balancer Controller 설치

인터넷 트래픽을 클러스터 내부로 전달하는 ALB(Application Load Balancer)를 관리하는 컨트롤러입니다.

```bash
# IAM Policy 다운로드 및 생성
curl -sSL https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json \
  -o /tmp/alb-iam-policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/alb-iam-policy.json

# IRSA 서비스 어카운트 생성
eksctl create iamserviceaccount \
  --cluster stockops-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts \
  --approve \
  --region "$AWS_REGION"

# Helm으로 컨트롤러 설치
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster --name stockops-cluster \
  --region "$AWS_REGION" \
  --query 'cluster.resourcesVpcConfig.vpcId' --output text)

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=stockops-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region="$AWS_REGION" \
  --set vpcId="$VPC_ID"
```

---

## 10단계: External Secrets Operator 설치

AWS Secrets Manager의 시크릿을 K8s Secret으로 자동 동기화하는 도구입니다.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true
```

---

## 11단계: K8s 매니페스트에 계정 ID 치환

`k8s/` 폴더의 YAML 파일 안 `<AWS_ACCOUNT_ID>` 를 실제 값으로 바꿉니다.

```bash
# Linux/Mac
find ./k8s -name "*.yaml" -exec \
  sed -i "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" {} \;

echo "치환 완료"
```

> Windows 환경이라면 Git Bash 또는 WSL2에서 위 명령을 실행하거나,
> `k8s/api/deployment.yaml`, `k8s/ai/deployment.yaml` 파일을 직접 열어
> `<AWS_ACCOUNT_ID>` 부분을 실제 12자리 계정 ID로 직접 수정합니다.

---

## 12단계: Kubernetes 리소스 배포

```bash
# 네임스페이스 생성
kubectl apply -f k8s/namespace.yaml

# 환경변수 ConfigMap
kubectl apply -f k8s/configmaps/

# Secrets Manager 연동 설정
kubectl apply -f k8s/external-secrets/

# 각 서비스 Deployment + Service + HPA
kubectl apply -f k8s/api/
kubectl apply -f k8s/ai/
kubectl apply -f k8s/admin-web/
kubectl apply -f k8s/client-web/

# ALB Ingress (인터넷 → 서비스 라우팅)
kubectl apply -f k8s/ingress/
```

---

## 13단계: 배포 확인

```bash
# Pod 상태 확인 (모두 Running 이어야 함, 1~2분 대기)
kubectl get pods -n stockops

# 예상 출력:
# NAME                                  READY   STATUS    RESTARTS
# stockops-api-xxxxxxxxx-xxxxx          1/1     Running   0
# stockops-ai-xxxxxxxxx-xxxxx           1/1     Running   0
# stockops-admin-web-xxxxxxxxx-xxxxx    1/1     Running   0
# stockops-client-web-xxxxxxxxx-xxxxx   1/1     Running   0

# ALB 접속 주소 확인 (약 2~3분 후 할당)
kubectl get ingress -n stockops

# API 헬스체크
ALB=$(kubectl get ingress stockops-ingress -n stockops \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "============================="
echo "접속 주소:"
echo "  클라이언트: http://$ALB/"
echo "  관리자:     http://$ALB/admin"
echo "  API:        http://$ALB/api/actuator/health"
echo "============================="

curl http://$ALB/api/actuator/health
```

---

## 이후 코드 수정 시 — 재배포 방법

코드 변경 후 서비스를 업데이트할 때는 해당 컴포넌트만 빌드해서 재배포합니다.

```bash
ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# 예) 관리자 웹 재배포
docker build -t $ECR/stockops-admin-web:latest ./stockops-admin-web
docker push $ECR/stockops-admin-web:latest
kubectl rollout restart deployment/stockops-admin-web -n stockops
kubectl rollout status deployment/stockops-admin-web -n stockops
```

### 서비스별 빌드 경로 & Deployment 이름

| 서비스 | 빌드 경로 | Deployment 이름 |
|---|---|---|
| API 서버 | `./stockops-api-server` | `stockops-api` |
| AI 모듈 | `./stockops-ai-module` | `stockops-ai` |
| 관리자 웹 | `./stockops-admin-web` | `stockops-admin-web` |
| 클라이언트 웹 | `./stockops-client-web` | `stockops-client-web` |

---

## 유용한 운영 명령어

```bash
# 실시간 로그 확인
kubectl logs -f deployment/stockops-api -n stockops
kubectl logs -f deployment/stockops-ai  -n stockops

# Pod 오류 원인 파악
kubectl describe pod -l app=stockops-api -n stockops

# 자동 스케일링(HPA) 현황
kubectl get hpa -n stockops

# 모든 리소스 한눈에 보기
kubectl get all -n stockops

# Secrets 변경 후 즉시 반영
kubectl rollout restart deployment/stockops-api -n stockops
```

---

## 문제 해결

### Pod이 `CrashLoopBackOff` 상태일 때

```bash
# 이전 종료 로그 확인
kubectl logs deployment/stockops-api -n stockops --previous

# 환경변수 주입 여부 확인
kubectl exec -n stockops deployment/stockops-api -- env | grep DB_HOST
```

**주요 원인**:
- `DB_HOST`가 비어있음 → Secrets Manager 값 누락 또는 ExternalSecret 미동기화
- DB 연결 실패 → RDS 보안 그룹이 EKS 노드 IP를 허용하지 않음

### ExternalSecret이 동기화되지 않을 때

```bash
kubectl describe externalsecret stockops-api-secret -n stockops
# Events 섹션의 오류 메시지 확인
```

### ALB 주소가 할당되지 않을 때

```bash
kubectl describe ingress stockops-ingress -n stockops
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

---

## 전체 자동화 스크립트 (3~12단계 한 번에)

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
chmod +x k8s/scripts/setup-eks.sh
./k8s/scripts/setup-eks.sh
```

> 스크립트 실행 전 **7단계 (Secrets Manager)** 는 반드시 실제 값으로 먼저 설정해야 합니다.

---

## 월 예상 비용 (ap-northeast-2, 최소 구성)

| 서비스 | 사양 | 월 비용 |
|---|---|---|
| EKS Control Plane | — | $73 |
| EC2 t3.medium × 2 | 워커 노드 | ~$65 |
| RDS db.t3.micro | PostgreSQL | ~$15 |
| ElastiCache cache.t3.micro | Redis | ~$12 |
| ALB | Ingress | ~$16 |
| ECR | 이미지 저장 | ~$1 |
| Secrets Manager | 2개 시크릿 | ~$1 |
| **합계** | | **~$183/월** |

