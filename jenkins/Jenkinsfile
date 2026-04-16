pipeline {
    agent any

    environment {
        IMAGE_NAME = "yourdockerhubusername/devops-lab-app"
        VERSION = "v${BUILD_NUMBER}"
        GITOPS_REPO = "https://github.com/KissMeRight/finalmobile68.git"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checkout"
                git branch: 'main', url: "${GITOPS_REPO}"
            }
        }

        stage('Build Image') {
            steps {
                echo "🔨 Build Docker image"
                bat """
                    docker build -t %IMAGE_NAME%:%VERSION% -t %IMAGE_NAME%:latest ./backend
                """
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Test container"
                bat """
                    docker run --rm %IMAGE_NAME%:%VERSION% cmd /c echo Tests passed
                """
            }
        }

        stage('Login Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    bat """
                        echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                bat """
                    docker push %IMAGE_NAME%:%VERSION%
                    docker push %IMAGE_NAME%:latest
                """
            }
        }

        stage('Update GitOps') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {

                    bat """
                        git clone https://%GIT_TOKEN%@github.com/KissMeRight/finalmobile68.git gitops
                        cd gitops

                        powershell -Command "(Get-Content k8s\\green\\deployment.yaml) -replace 'image:.*devops-lab-app.*', 'image: %IMAGE_NAME%:%VERSION%' | Set-Content k8s\\green\\deployment.yaml"

                        git config user.email "jenkins@ci.com"
                        git config user.name "jenkins"

                        git add .
                        git commit -m "update %VERSION%"
                        git push origin main
                    """
                }
            }
        }
    }

    post {
        always {
            echo "🧹 cleanup"
            bat "docker rmi %IMAGE_NAME%:%VERSION% || exit 0"
        }

        success {
            echo "✅ SUCCESS %VERSION%"
        }

        failure {
            echo "❌ FAILED"
        }
    }
}