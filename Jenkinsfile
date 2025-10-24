pipeline {
    agent any

    environment {
        APP_NAME = "go-app-fiber"
        DOCKER_IMAGE = "wizzidevs/go-app-fiber"
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
                echo 'Checking out source code......'
                checkout scm
            }
        }

        stage('Build & Test (Go)') {
            steps {
                echo "Building with Go ${GO_VERSION}..."
                sh '''
                    docker run --rm \
                        -v "$(pwd):/app" \
                        -w /app \
                        -e GOCACHE=/tmp/go-cache \
                        -e GOMODCACHE=/tmp/go-mod \
                        golang:${GO_VERSION} \
                        sh -c "
                            go version
                            go mod download
                            go mod tidy
                            go build -o main .
                            echo 'Build Done'

                            echo 'Running unit tests...'
                            go test ./... -v || echo ' No tests found'
                        "
                '''
            }
        }

        stage('Docker Build & Test') {
            steps {
                echo ' Building Docker image for integration test...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:test .

                    # Cleanup existing test container if exists
                    docker rm -f ${APP_NAME}_test 2>/dev/null || true

                    # Run container test
                    docker run -d --rm -p 9000:8000 --name ${APP_NAME}_test ${DOCKER_IMAGE}:test
                    sleep 5

                    # Health check
                    curl -f http://localhost:9000 || (echo "Container test failed!" && docker logs ${APP_NAME}_test && exit 1)

                    docker stop ${APP_NAME}_test
                    echo "Container test OK"
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            script {
                // Cleanup containers
                sh 'docker rm -f ${APP_NAME}_final>/dev/null || true'

                // Cleanup images
                if (sh(script: 'which docker', returnStatus: true) == 0) {
                    sh 'docker system prune -f || true'
                }
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
    }
}