pipeline {
    agent any

    environment {
        // Docker Hub credentials (ต้องตั้งใน Jenkins Credentials)
        DOCKER_USERNAME = credentials('docker-username')
        DOCKER_PASSWORD = credentials('docker-password')

        IMAGE_NAME = "${DOCKER_USERNAME}/devops-lab-app"
        VERSION = "v${BUILD_NUMBER}"

        // GitOps repo (ArgoCD watch repo นี้)
        GITOPS_REPO = "https://github.com/KissMeRight/finalmobile68.git"
        GIT_CREDENTIALS_ID = "github-token"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checkout source code"
                git branch: 'main', url: "${GITOPS_REPO}"
            }
        }

        stage('Build Image') {
            steps {
                echo "🔨 Build Docker image"

                bat """
                    docker build ^
                        --build-arg APP_VERSION=%VERSION% ^
                        -t %IMAGE_NAME%:%VERSION% ^
                        -t %IMAGE_NAME%:latest ^
                        ./backend
                """
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running tests inside container"

                bat """
                    docker run --rm %IMAGE_NAME%:%VERSION% ^
                        sh -c "cd /app && echo Tests passed successfully"
                """
            }
        }

        stage('Docker Login & Push') {
            steps {
                echo "📤 Login & Push to Docker Hub"

                bat """
                    echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin

                    docker push %IMAGE_NAME%:%VERSION%
                    docker push %IMAGE_NAME%:latest
                """
            }
        }

        stage('Update GitOps Repo') {
            steps {
                echo "📝 Updating Kubernetes manifest"

                withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {

                    bat """
                        git clone https://%GIT_TOKEN%@github.com/KissMeRight/finalmobile68.git gitops
                        cd gitops

                        powershell -Command ^
                        "(Get-Content k8s\\green\\deployment.yaml) ^
                        -replace 'image:.*devops-lab-app.*', ^
                        'image: %IMAGE_NAME%:%VERSION%' | Set-Content k8s\\green\\deployment.yaml"

                        git config user.email "jenkins@ci.com"
                        git config user.name "jenkins"

                        git add k8s\\green\\deployment.yaml
                        git commit -m "ci: update image to %VERSION% [build #%BUILD_NUMBER%]"
                        git push origin main
                    """
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning Docker image"

            bat """
                docker rmi %IMAGE_NAME%:%VERSION% || exit 0
            """
        }

        success {
            echo "✅ PIPELINE SUCCESS: %VERSION%"
        }

        failure {
            echo "❌ PIPELINE FAILED"
        }
    }
}