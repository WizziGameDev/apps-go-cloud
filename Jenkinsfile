pipeline {
    agent any

    environment {
        APP_NAME = "go-fiber-app"
        DOCKER_IMAGE = "wizzidevs/go-fiber-app"
        DOCKER_TAG = "latest"
        DOCKER_CREDENTIALS = "dockerhub-credentials"
        GO_VERSION = "1.25.1"
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

        stage('Build & Test (Go)') {
            agent {
                docker {
                    image "golang:${GO_VERSION}-alpine"
                    args '''
                        -u 1000:1000  # Add this to run as a user that has permission
                        -v $HOME/go/pkg/mod:/go/pkg/mod
                        -v /tmp/go-cache:/go/.cache
                    '''
                }
            }
            environment {
                GOCACHE = "/go/.cache"
                GOTMPDIR = "/go/tmp"
            }
            steps {
                echo "🔧 Using Go ${GO_VERSION}..."
                sh '''
                    # Ensure temporary directory exists
                    mkdir -p /go/tmp
                    go version
                    go mod tidy
                    go build -o main .
                    echo "✅ Build OK"

                    echo "🧪 Running unit tests..."
                    go test ./... -v
                '''
            }
        }

        // 🧩 TEST Docker image di host Jenkins
        stage('Docker Build & Test') {
            steps {
                echo '🐳 Building Docker image for integration test...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:test .
                    docker run -d --rm -p 9000:8000 --name ${APP_NAME}_test ${DOCKER_IMAGE}:test
                    sleep 5
                    curl -f http://localhost:9000 || (echo "❌ Container test failed!" && exit 1)
                    docker stop ${APP_NAME}_test
                    echo "✅ Container test OK"
                '''
            }
        }

        // 🚀 Push ke Docker Hub (hanya untuk main/staging)
        stage('Push to Docker Hub') {
            when {
                anyOf {
                    branch 'main'
                    branch 'staging'
                }
            }
            steps {
                echo '📦 Pushing image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS}") {
                            sh '''
                                docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            script {
                // Only prune Docker system if Docker is installed
                if (sh(script: 'which docker', returnStatus: true) == 0) {
                    sh 'docker system prune -f || true'
                }
            }
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above.'
        }
    }
}
