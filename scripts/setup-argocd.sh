#!/bin/bash
# =============================================================
# Setup ArgoCD บน Minikube
# ArgoCD จะ watch GitOps repo และ sync กับ K8s อัตโนมัติ
# =============================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️]${NC} $1"; }

echo "========================================="
echo "  Setting up ArgoCD"
echo "========================================="

# ─── 1. ติดตั้ง ArgoCD namespace + components ────────────────
echo ""
echo "📦 Step 1: Install ArgoCD"
kubectl create namespace argocd 2>/dev/null || warn "namespace argocd already exists"

kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log "ArgoCD manifests applied"

# ─── 2. รอให้ ArgoCD pods พร้อม ──────────────────────────────
echo ""
echo "⏳ Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=available \
  --timeout=120s \
  deployment/argocd-server \
  -n argocd

log "ArgoCD server ready"

# ─── 3. Patch ArgoCD service เป็น NodePort ───────────────────
echo ""
echo "🔧 Step 3: Expose ArgoCD UI via NodePort"
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort"}}'

# ดู NodePort ที่ได้
ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
MINIKUBE_IP=$(minikube ip)

log "ArgoCD UI: https://$MINIKUBE_IP:$ARGOCD_PORT"

# ─── 4. ดึง initial password ─────────────────────────────────
echo ""
echo "🔑 ArgoCD Initial Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "(Username: admin)"

# ─── 5. ติดตั้ง ArgoCD CLI ───────────────────────────────────
echo ""
echo "📦 Step 4: Install ArgoCD CLI"
if command -v argocd &>/dev/null; then
  log "argocd CLI already installed"
else
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install argocd
  else
    curl -sSL -o /usr/local/bin/argocd \
      https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
  fi
  log "ArgoCD CLI installed"
fi

echo ""
echo "========================================="
echo "  ArgoCD Setup Complete!"
echo "========================================="
echo ""
echo "ArgoCD UI: https://$MINIKUBE_IP:$ARGOCD_PORT"
echo "Username:  admin"
echo ""
echo "Next: รัน scripts/setup-argocd-app.sh"
echo "      เพื่อสร้าง ArgoCD Application"
