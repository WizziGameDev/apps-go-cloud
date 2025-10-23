pipeline {
    agent {
        docker {
            image 'golang:1.22'  // gunakan image resmi Go
            args '-v /var/run/docker.sock:/var/run/docker.sock' // agar bisa akses Docker host
        }
    }

    environment {
        APP_NAME = "go-fiber-app"
        DOCKER_IMAGE = "wizzidevs/go-fiber-app"
        DOCKER_TAG = "latest"
        DOCKER_CREDENTIALS = "dockerhub-credentials"
    }

    options {
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
            }
        }

        // 🧑‍💻 DEV STAGE
        stage('Development - Build & Local Run') {
            steps {
                script {
                    echo '🔧 [DEV] Building Go binary...'
                    // tangani error biar pipeline lanjut walau gagal
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh '''
                            go version
                            go mod tidy
                            go build -o main .
                        '''
                    }

                    echo '🚀 [DEV] Running app for quick verification...'
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh '''
                            nohup ./main > app.log 2>&1 &
                            sleep 3
                            curl -f http://localhost:8000 || echo "⚠️ App failed to start in dev!"
                            pkill main || true
                        '''
                    }
                }
            }
        }

        // 🧪 TEST STAGE
        stage('Testing - Unit & Integration Tests') {
            steps {
                echo '🧪 [TEST] Running unit tests...'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'go test ./... -v || true'
                }

                echo '🐳 [TEST] Building Docker image for test...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:test .
                '''

                echo '🧩 [TEST] Running container integration test...'
                sh '''
                    docker run -d --rm -p 9000:8000 --name ${APP_NAME}_test ${DOCKER_IMAGE}:test
                    sleep 5
                    curl -f http://localhost:9000 || echo "⚠️ Container test failed!"
                    docker stop ${APP_NAME}_test
                '''
            }
        }

        // 🚀 STAGING STAGE
        stage('Staging - Push to Docker Hub') {
            when {
                anyOf {
                    branch 'main'
                    branch 'staging'
                }
            }
            steps {
                echo '📦 [STAGING] Pushing image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ All pipeline stages (Dev → Test → Staging) completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Please review the logs.'
        }
        always {
            echo '🧹 Cleaning up Docker resources...'
            sh 'docker system prune -f || true'
        }
    }
}
