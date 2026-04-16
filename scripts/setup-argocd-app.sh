#!/bin/bash
# =============================================================
# สร้าง ArgoCD Application หลังจาก ArgoCD พร้อมแล้ว
# ใช้: ./scripts/setup-argocd-app.sh
# =============================================================

set -e
GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[✅]${NC} $1"; }

MINIKUBE_IP=$(minikube ip)
ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
ARGOCD_SERVER="$MINIKUBE_IP:$ARGOCD_PORT"

echo "Connecting to ArgoCD at: $ARGOCD_SERVER"

# ดึง password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# Login (ignore certificate สำหรับ local dev)
argocd login $ARGOCD_SERVER \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

log "Logged in to ArgoCD"

# สร้าง Application จาก manifest
kubectl apply -f k8s/argocd/application.yaml

log "ArgoCD Application created: devops-lab"

# ดู status
echo ""
echo "Application status:"
argocd app get devops-lab

echo ""
log "ArgoCD will now watch your GitOps repo and auto-deploy on changes"
echo ""
echo "Manual sync command:"
echo "  argocd app sync devops-lab"
echo ""
echo "Watch status:"
echo "  argocd app wait devops-lab --health"
