#!/usr/bin/env bash
# =============================================================================
# StockOps EKS 클러스터 초기 설정 스크립트
# 실행 전 AWS CLI, eksctl, helm, kubectl이 설치되어 있어야 합니다.
#
# 사용법:
#   chmod +x setup-eks.sh
#   AWS_ACCOUNT_ID=123456789012 ./setup-eks.sh
# =============================================================================
set -euo pipefail

# ──────────────────────────────────────────────────────────
# 변수 설정 (환경변수로 오버라이드 가능)
# ──────────────────────────────────────────────────────────
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?'AWS_ACCOUNT_ID 환경변수를 설정하세요'}"
CLUSTER_NAME="${CLUSTER_NAME:-stockops-cluster}"
NODE_TYPE="${NODE_TYPE:-t3.medium}"
NODE_MIN="${NODE_MIN:-2}"
NODE_MAX="${NODE_MAX:-4}"
K8S_NAMESPACE="stockops"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "======================================================"
echo " StockOps EKS 배포 설정 시작"
echo " Region      : ${AWS_REGION}"
echo " Account ID  : ${AWS_ACCOUNT_ID}"
echo " Cluster     : ${CLUSTER_NAME}"
echo " Node type   : ${NODE_TYPE}"
echo "======================================================"

# ──────────────────────────────────────────────────────────
# STEP 1: ECR 리포지터리 생성
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 1] ECR 리포지터리 생성..."
for repo in stockops-api stockops-ai stockops-client-web stockops-admin-web; do
  if aws ecr describe-repositories --repository-names "${repo}" --region "${AWS_REGION}" &>/dev/null; then
    echo "  - ${repo}: 이미 존재함"
  else
    aws ecr create-repository \
      --repository-name "${repo}" \
      --region "${AWS_REGION}" \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=AES256 \
      --tags Key=Project,Value=stockops Key=Environment,Value=production \
      > /dev/null
    echo "  - ${repo}: 생성 완료"
  fi
done

# ──────────────────────────────────────────────────────────
# STEP 2: EKS 클러스터 생성 (약 15~20분 소요)
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 2] EKS 클러스터 생성 (약 15~20분 소요)..."
if eksctl get cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}" &>/dev/null; then
  echo "  - 클러스터 '${CLUSTER_NAME}' 이미 존재함"
else
  eksctl create cluster \
    --name "${CLUSTER_NAME}" \
    --region "${AWS_REGION}" \
    --nodegroup-name stockops-nodes \
    --node-type "${NODE_TYPE}" \
    --nodes "${NODE_MIN}" \
    --nodes-min "${NODE_MIN}" \
    --nodes-max "${NODE_MAX}" \
    --managed \
    --with-oidc \
    --alb-ingress-access \
    --full-ecr-access \
    --tags "Project=stockops,Environment=production"
  echo "  - 클러스터 생성 완료"
fi

# kubeconfig 업데이트
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
echo "  - kubeconfig 업데이트 완료"

# ──────────────────────────────────────────────────────────
# STEP 3: AWS Load Balancer Controller 설치
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 3] AWS Load Balancer Controller 설치..."
# IAM Policy 생성
if ! aws iam get-policy \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
    &>/dev/null; then
  curl -sSL https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json \
    -o /tmp/alb-iam-policy.json
  aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file:///tmp/alb-iam-policy.json \
    > /dev/null
  echo "  - IAM Policy 생성 완료"
fi

# IAM Service Account 생성 (IRSA)
eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts \
  --approve \
  --region "${AWS_REGION}"

# Helm으로 컨트롤러 설치
helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
helm repo update eks

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${CLUSTER_NAME}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region="${AWS_REGION}" \
  --set vpcId="$(aws eks describe-cluster --name "${CLUSTER_NAME}" \
      --region "${AWS_REGION}" --query 'cluster.resourcesVpcConfig.vpcId' --output text)"
echo "  - AWS Load Balancer Controller 설치 완료"

# ──────────────────────────────────────────────────────────
# STEP 4: External Secrets Operator 설치
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 4] External Secrets Operator 설치..."
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets

helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true
echo "  - External Secrets Operator 설치 완료"

# ──────────────────────────────────────────────────────────
# STEP 5: CloudWatch Container Insights 설치
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 5] CloudWatch Container Insights (FluentBit + CW Agent)..."
ClusterName="${CLUSTER_NAME}"
RegionName="${AWS_REGION}"
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
FluentBitReadFromTail='On'

curl -sSL https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml \
  | sed \
    -e "s/{{cluster_name}}/${ClusterName}/g" \
    -e "s/{{region_name}}/${RegionName}/g" \
    -e "s/{{http_server_toggle}}/${FluentBitHttpPort}/g" \
    -e "s/{{http_server_port}}/${FluentBitHttpPort}/g" \
    -e "s/{{read_from_head}}/${FluentBitReadFromHead}/g" \
    -e "s/{{read_from_tail}}/${FluentBitReadFromTail}/g" \
  | kubectl apply -f -
echo "  - CloudWatch Container Insights 설치 완료"

# ──────────────────────────────────────────────────────────
# STEP 6: AWS Secrets Manager에 시크릿 생성 (빈 값으로 초기화)
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 6] AWS Secrets Manager 시크릿 초기화..."
if ! aws secretsmanager describe-secret \
    --secret-id "stockops/prod/api" --region "${AWS_REGION}" &>/dev/null; then
  aws secretsmanager create-secret \
    --name "stockops/prod/api" \
    --region "${AWS_REGION}" \
    --description "StockOps API Server secrets" \
    --secret-string '{
      "DB_HOST": "REPLACE_WITH_RDS_ENDPOINT",
      "DB_USER": "stockops",
      "DB_PASSWORD": "REPLACE_WITH_STRONG_PASSWORD",
      "JWT_SECRET": "REPLACE_WITH_MIN_32_CHAR_SECRET",
      "SPRING_DATA_REDIS_HOST": "REPLACE_WITH_ELASTICACHE_ENDPOINT",
      "SPRING_MAIL_HOST": "email-smtp.ap-northeast-2.amazonaws.com",
      "SPRING_MAIL_USERNAME": "REPLACE_WITH_SES_SMTP_USERNAME",
      "SPRING_MAIL_PASSWORD": "REPLACE_WITH_SES_SMTP_PASSWORD"
    }' > /dev/null
  echo "  - stockops/prod/api 시크릿 생성 (값 교체 필요)"
else
  echo "  - stockops/prod/api 이미 존재"
fi

if ! aws secretsmanager describe-secret \
    --secret-id "stockops/prod/ai" --region "${AWS_REGION}" &>/dev/null; then
  aws secretsmanager create-secret \
    --name "stockops/prod/ai" \
    --region "${AWS_REGION}" \
    --description "StockOps AI Module secrets" \
    --secret-string '{
      "DATABASE_URL": "postgresql://stockops:REPLACE_PASSWORD@REPLACE_RDS_ENDPOINT:5432/stockops",
      "AI_MODULE_API_KEY": "REPLACE_WITH_API_KEY"
    }' > /dev/null
  echo "  - stockops/prod/ai 시크릿 생성 (값 교체 필요)"
else
  echo "  - stockops/prod/ai 이미 존재"
fi

# ──────────────────────────────────────────────────────────
# STEP 7: K8s 매니페스트의 AWS_ACCOUNT_ID 플레이스홀더 치환
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 7] 매니페스트 파일 AWS_ACCOUNT_ID 치환..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/.."

# Windows에서는 sed -i 대신 다른 방법 필요할 수 있음
find "${K8S_DIR}" -name "*.yaml" -type f | while read -r file; do
  if grep -q "<AWS_ACCOUNT_ID>" "${file}" 2>/dev/null; then
    sed -i "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" "${file}"
    echo "  - 치환 완료: ${file}"
  fi
done

# ──────────────────────────────────────────────────────────
# STEP 8: K8s 매니페스트 배포
# ──────────────────────────────────────────────────────────
echo ""
echo "[STEP 8] Kubernetes 리소스 배포..."
kubectl apply -f "${K8S_DIR}/namespace.yaml"
kubectl apply -f "${K8S_DIR}/configmaps/"
kubectl apply -f "${K8S_DIR}/external-secrets/"
kubectl apply -f "${K8S_DIR}/api/"
kubectl apply -f "${K8S_DIR}/ai/"
kubectl apply -f "${K8S_DIR}/client-web/"
kubectl apply -f "${K8S_DIR}/admin-web/"
kubectl apply -f "${K8S_DIR}/ingress/"

echo ""
echo "======================================================"
echo " 설정 완료!"
echo ""
echo " 다음 단계:"
echo " 1. AWS Secrets Manager 시크릿 실제 값으로 업데이트"
echo "    aws secretsmanager update-secret \\"
echo "      --secret-id stockops/prod/api \\"
echo "      --secret-string '{...실제 값...}'"
echo ""
echo " 2. RDS PostgreSQL 및 ElastiCache Redis 생성"
echo "    (Terraform 또는 AWS 콘솔 사용)"
echo ""
echo " 3. ALB DNS 확인"
echo "    kubectl get ingress -n stockops"
echo ""
echo " 4. Pod 상태 확인"
echo "    kubectl get pods -n stockops"
echo "======================================================"
