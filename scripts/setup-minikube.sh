#!/bin/bash
# =============================================================
# DevOps Lab - Minikube Setup Script
# รันครั้งเดียวเพื่อ setup environment ทั้งหมด
# =============================================================

set -e  # หยุดทันทีถ้ามี error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✅ OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️  WARN]${NC} $1"; }
err()  { echo -e "${RED}[❌ ERR]${NC} $1"; }

echo "========================================="
echo "  DevOps Lab - Minikube Setup"
echo "========================================="

# ─── 1. ติดตั้ง kubectl ──────────────────────────────────────
echo ""
echo "📦 Step 1: Install kubectl"
if command -v kubectl &> /dev/null; then
  log "kubectl already installed: $(kubectl version --client --short 2>/dev/null)"
else
  # macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install kubectl
  # Linux
  else
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
  fi
  log "kubectl installed"
fi

# ─── 2. ติดตั้ง Minikube ─────────────────────────────────────
echo ""
echo "📦 Step 2: Install Minikube"
if command -v minikube &> /dev/null; then
  log "Minikube already installed: $(minikube version --short)"
else
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install minikube
  else
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    sudo mv minikube-linux-amd64 /usr/local/bin/minikube
  fi
  log "Minikube installed"
fi

# ─── 3. Start Minikube ───────────────────────────────────────
echo ""
echo "🚀 Step 3: Start Minikube"
if minikube status | grep -q "Running"; then
  log "Minikube already running"
else
  minikube start \
    --driver=docker \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g
  log "Minikube started"
fi

# ดู IP ของ Minikube
MINIKUBE_IP=$(minikube ip)
log "Minikube IP: $MINIKUBE_IP"

# ─── 4. Enable addons ────────────────────────────────────────
echo ""
echo "🔧 Step 4: Enable Minikube addons"
minikube addons enable ingress        # Nginx Ingress Controller
minikube addons enable metrics-server # สำหรับ kubectl top
log "Addons enabled"

# ─── 5. Deploy Blue-Green ────────────────────────────────────
echo ""
echo "🔵🟢 Step 5: Deploy Blue-Green"

# ตรวจสอบว่าได้ set username แล้วหรือยัง
if grep -q "YOUR_DOCKERHUB_USERNAME" k8s/blue/deployment.yaml; then
  warn "Please edit k8s/blue/deployment.yaml and k8s/green/deployment.yaml"
  warn "Replace YOUR_DOCKERHUB_USERNAME with your actual Docker Hub username"
  warn "Skipping blue-green deploy for now..."
else
  kubectl apply -f k8s/blue/deployment.yaml
  kubectl apply -f k8s/green/deployment.yaml
  kubectl apply -f k8s/service.yaml
  log "Blue-Green deployments applied"
fi

# ─── 6. Verify ───────────────────────────────────────────────
echo ""
echo "✅ Step 6: Verify setup"
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Pods:"
kubectl get pods -A
echo ""
echo "Services:"
kubectl get svc

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Minikube IP: $MINIKUBE_IP"
echo "App URL:     http://$MINIKUBE_IP:30080"
echo "Backend URL: http://$MINIKUBE_IP:30300"
echo ""
echo "Next steps:"
echo "  1. Build & push Docker images (see scripts/build-push.sh)"
echo "  2. Setup Jenkins (see scripts/setup-jenkins.sh)"
echo "  3. Setup ArgoCD (see scripts/setup-argocd.sh)"
echo ""
