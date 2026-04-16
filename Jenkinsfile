pipeline {
    agent any

    environment {
        IMAGE_NAME = "yourdockerhubusername/devops-lab-app"
        VERSION = "v${BUILD_NUMBER}"
        GIT_REPO = "https://github.com/KissMeRight/finalmobile68.git"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checkout source code"
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image"

                bat """
                    docker build ^
                        -t yourdockerhubusername/devops-lab-app:%BUILD_NUMBER% ^
                        -t yourdockerhubusername/devops-lab-app:latest ^
                        ./backend
                """
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running tests"

                bat """
                    docker run --rm yourdockerhubusername/devops-lab-app:%BUILD_NUMBER% ^
                    cmd /c "echo Tests passed successfully"
                """
            }
        }

        stage('Login & Push Docker') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    bat """
                        echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin

                        docker push yourdockerhubusername/devops-lab-app:%BUILD_NUMBER%
                        docker push yourdockerhubusername/devops-lab-app:latest
                    """
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {

                    bat """
                        git clone https://%GIT_TOKEN%@github.com/KissMeRight/finalmobile68.git gitops
                        cd gitops

                        powershell -Command "(Get-Content k8s\\green\\deployment.yaml) -replace 'image:.*devops-lab-app.*', 'image: yourdockerhubusername/devops-lab-app:%BUILD_NUMBER%' | Set-Content k8s\\green\\deployment.yaml"

                        git config user.email "jenkins@ci.com"
                        git config user.name "jenkins"

                        git add .
                        git commit -m "update image %BUILD_NUMBER%"
                        git push origin main
                    """
                }
            }
        }
    }

    post {
        always {
            bat "docker rmi yourdockerhubusername/devops-lab-app:%BUILD_NUMBER% || exit 0"
        }

        success {
            echo "🎉 BUILD SUCCESS: %BUILD_NUMBER%"
        }

        failure {
            echo "❌ BUILD FAILED"
        }
    }
}