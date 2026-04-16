#!/bin/bash
# =============================================================
# Setup Prometheus + Grafana บน Minikube
# =============================================================

set -e
GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[✅]${NC} $1"; }

MINIKUBE_IP=$(minikube ip)

echo "========================================="
echo "  Setup Monitoring Stack"
echo "========================================="

# Deploy ทุกอย่าง
echo "Deploying Prometheus..."
kubectl apply -f k8s/monitoring/prometheus.yaml
log "Prometheus deployed"

echo "Deploying Node Exporter + kube-state-metrics..."
kubectl apply -f k8s/monitoring/exporters.yaml
log "Exporters deployed"

echo "Deploying Grafana..."
kubectl apply -f k8s/monitoring/grafana.yaml
log "Grafana deployed"

# รอให้ pods พร้อม
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  deployment/prometheus deployment/grafana \
  deployment/kube-state-metrics \
  -n monitoring

log "All monitoring pods ready"

echo ""
echo "========================================="
echo "  Monitoring Ready!"
echo "========================================="
echo ""
echo "Prometheus: http://$MINIKUBE_IP:30090"
echo "Grafana:    http://$MINIKUBE_IP:30030"
echo "            Username: admin"
echo "            Password: devopslab123"
echo ""
echo "Grafana: Import dashboard IDs ที่แนะนำ:"
echo "  1860  - Node Exporter Full"
echo "  315   - Kubernetes cluster monitoring"
echo "  6417  - Kubernetes Pods"
echo ""
echo "วิธี Import: Grafana > + > Import > ใส่ Dashboard ID > Load"
