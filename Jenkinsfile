pipeline {
    agent any

    environment {
        AWS_REGION       = 'ap-south-1'
        ECR_REPOSITORY   = 'taskflow-frontend'
        EKS_CLUSTER_NAME = 'taskflow-eks'
        K8S_NAMESPACE    = 'default'
        DEPLOYMENT_NAME  = 'taskflow-frontend'
        IMAGE_TAG        = "${env.BUILD_NUMBER}"
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }
   
    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Frontend') {
            steps {
                
                sh '''
                    docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp \
                        -v "$PWD/frontend":/app -w /app \
                        node:22-alpine sh -c "npm ci && npm run build"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                   
                    env.AWS_ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()
                    env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                    env.IMAGE_URI    = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
                }
               
                sh 'docker build -t "$IMAGE_URI" .'
            }
        }

        stage('Login to ECR') {
            steps {
                sh 'aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"'
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh 'docker push "$IMAGE_URI"'
            }
        }

        stage('Configure kubectl') {
            steps {
                sh 'aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"'
            }
        }

        stage('Deploy to EKS') {
            steps {
                
                sh '''
                    sed "s|IMAGE_URI_PLACEHOLDER|$IMAGE_URI|" k8s/deployment.yaml | kubectl apply -n "$K8S_NAMESPACE" -f -
                    kubectl apply -n "$K8S_NAMESPACE" -f k8s/service.yaml
                '''
            }
        }

        stage('Verify Rollout') {
            steps {
                
                sh 'kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$K8S_NAMESPACE" --timeout=180s'
                
                sh 'kubectl get deployment "$DEPLOYMENT_NAME" -n "$K8S_NAMESPACE" -o wide'
            }
        }
    }

    post {
        always {
            sh 'docker image rm "$IMAGE_URI" || true'
        }
        success {
            echo "Deployed ${env.IMAGE_URI} to ${env.EKS_CLUSTER_NAME}"
        }
        failure {
            echo 'Pipeline failed. Check the stage logs above.'
        }
    }
}
