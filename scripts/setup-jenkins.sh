#!/bin/bash
# =============================================================
# Setup Jenkins ใน Docker container
# Jenkins จะรันบนเครื่อง และเชื่อมกับ Docker + K8s
# =============================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️]${NC} $1"; }

echo "========================================="
echo "  Setting up Jenkins"
echo "========================================="

# สร้าง volume สำหรับ Jenkins data
docker volume create jenkins-data 2>/dev/null || true

# รัน Jenkins container
# - Port 8080 = Jenkins UI
# - Port 50000 = Jenkins agent communication
# - Mount docker.sock = ให้ Jenkins สั่ง docker build ได้
# - Mount kubeconfig = ให้ Jenkins สั่ง kubectl ได้
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.kube:/root/.kube:ro \
  jenkins/jenkins:lts-jdk17

log "Jenkins container started"

# รอให้ Jenkins พร้อม
echo "Waiting for Jenkins to start..."
sleep 20

# ดึง initial admin password
echo ""
echo "========================================="
log "Jenkins is running at: http://localhost:8080"
echo ""
echo "Initial Admin Password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
echo ""
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. เปิด http://localhost:8080"
echo "  2. ใส่ password จากด้านบน"
echo "  3. ติดตั้ง suggested plugins"
echo "  4. สร้าง admin user"
echo "  5. สร้าง Pipeline job ชื่อ 'devops-lab'"
echo "  6. ใส่ Jenkinsfile จาก jenkins/Jenkinsfile"
echo ""
warn "ต้องติดตั้ง Docker Pipeline plugin ด้วย:"
warn "  Jenkins > Manage Jenkins > Plugins > Docker Pipeline"
