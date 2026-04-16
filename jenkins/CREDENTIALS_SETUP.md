# วิธีตั้งค่า Jenkins Credentials
# Jenkins > Manage Jenkins > Credentials > System > Global > Add Credential

## 1. Docker Hub Username
Kind:   Secret text
ID:     docker-username
Secret: your-dockerhub-username

## 2. Docker Hub Password / Access Token
Kind:   Secret text
ID:     docker-password
Secret: your-dockerhub-password-or-token
# แนะนำใช้ Access Token แทน password
# สร้างที่: https://hub.docker.com/settings/security

## 3. GitHub Personal Access Token
Kind:   Secret text
ID:     github-token
Secret: ghp_xxxxxxxxxxxxxxxxxxxx
# สร้างที่: GitHub > Settings > Developer settings > Personal access tokens
# Permissions ที่ต้องการ: repo (read + write)

# ─── วิธีสร้าง Pipeline Job ────────────────────────────────────
# 1. Jenkins > New Item
# 2. ตั้งชื่อ: devops-lab
# 3. เลือก: Pipeline
# 4. Pipeline section:
#    - Definition: Pipeline script from SCM
#    - SCM: Git
#    - Repository URL: https://github.com/YOUR_USERNAME/devops-lab.git
#    - Branch: */main
#    - Script Path: jenkins/Jenkinsfile
# 5. Save

# ─── วิธีใช้ GitHub Webhook (แนะนำ) ────────────────────────────
# แทน pollSCM ใช้ Webhook ดีกว่า เพราะ build ทันทีเมื่อ push
# 
# GitHub repo > Settings > Webhooks > Add webhook
# Payload URL: http://YOUR_SERVER_IP:8080/github-webhook/
# Content type: application/json
# Event: Just the push event
#
# Jenkins > Pipeline job > Configure > Build Triggers
# ✅ GitHub hook trigger for GITScm polling
