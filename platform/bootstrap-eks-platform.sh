#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-south-1}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-shopnow-eks}"
K8S_NAMESPACE="${K8S_NAMESPACE:-shopnow}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"

VPC_ID="$(cd "${TERRAFORM_DIR}" && terraform output -raw vpc_id)"
LBC_ROLE_ARN="$(cd "${TERRAFORM_DIR}" && terraform output -raw aws_load_balancer_controller_role_arn)"

aws eks update-kubeconfig --region "${AWS_REGION}" --name "${EKS_CLUSTER_NAME}"

kubectl get namespace "${K8S_NAMESPACE}" >/dev/null 2>&1 || \
  kubectl create namespace "${K8S_NAMESPACE}"

echo "Creating ShopNow gp3 StorageClass..."

kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: shopnow-gp3
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
parameters:
  type: gp3
  fsType: ext4
EOF

# AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo update eks

kubectl -n kube-system create serviceaccount aws-load-balancer-controller \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n kube-system annotate serviceaccount aws-load-balancer-controller \
  eks.amazonaws.com/role-arn="${LBC_ROLE_ARN}" --overwrite

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="${EKS_CLUSTER_NAME}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region="${AWS_REGION}" \
  --set vpcId="${VPC_ID}" \
  --version 1.14.0 \
  --wait \
  --timeout 10m

# kube-prometheus-stack is a cluster/platform component, not an application dependency.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update prometheus-community

helm upgrade --install shopnow-monitoring \
  prometheus-community/kube-prometheus-stack \
  --namespace "${K8S_NAMESPACE}" \
  --values "${ROOT_DIR}/platform/kube-prometheus-values.yaml" \
  --version 87.18.1 \
  --wait \
  --timeout 15m

echo
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n "${K8S_NAMESPACE}"
echo
kubectl top nodes
