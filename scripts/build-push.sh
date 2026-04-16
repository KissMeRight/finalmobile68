#!/bin/bash
# =============================================================
# Build Docker image แล้ว push ขึ้น Docker Hub
# ใช้: ./scripts/build-push.sh v2
# =============================================================

set -e

DOCKER_USERNAME="hanaari"
IMAGE_NAME="$DOCKER_USERNAME/devops-lab-app"
VERSION=${1:-"v1"}   # รับ version จาก argument, default = v1

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[✅]${NC} $1"; }

echo "Building image: $IMAGE_NAME:$VERSION"

# Build image
docker build \
  --build-arg APP_VERSION=$VERSION \
  -t $IMAGE_NAME:$VERSION \
  -t $IMAGE_NAME:latest \
  ./backend

log "Build complete: $IMAGE_NAME:$VERSION"

# Login Docker Hub (ถ้ายังไม่ได้ login)
if ! docker info 2>/dev/null | grep -q "Username"; then
  echo "Please login to Docker Hub:"
  docker login
fi

# Push
docker push $IMAGE_NAME:$VERSION
docker push $IMAGE_NAME:latest

log "Pushed: $IMAGE_NAME:$VERSION"
echo ""
echo "Image ready: $IMAGE_NAME:$VERSION"
echo "Update k8s/green/deployment.yaml to use this image"
