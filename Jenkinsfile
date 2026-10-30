// CI/CD pipeline: build the React frontend, push the image to Amazon ECR,
// and deploy it to Amazon EKS.
//
// Runs on the Jenkins EC2 instance created by Terraform. AWS access comes from
// the instance's IAM role, so no AWS keys are stored in Jenkins.

pipeline {
    agent any

    environment {
        // Must match the values in terraform/variables.tf and k8s/deployment.yaml
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

    // Check GitHub for new commits about every 5 minutes. Jenkins only accepts
    // traffic from your IP, so GitHub webhooks cannot reach it. Polling works
    // without opening Jenkins to the internet. Active after the first manual build.
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
                dir('frontend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Look up the AWS account ID from the instance role instead of hardcoding it
                    env.AWS_ACCOUNT_ID = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()
                    env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                    env.IMAGE_URI    = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
                }
                // Build context is the repository root
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
                // Replace the image placeholder with the image we just pushed, then apply.
                // This both creates the Deployment (first run) and updates its image (later runs).
                sh '''
                    sed "s|IMAGE_URI_PLACEHOLDER|$IMAGE_URI|" k8s/deployment.yaml | kubectl apply -n "$K8S_NAMESPACE" -f -
                    kubectl apply -n "$K8S_NAMESPACE" -f k8s/service.yaml
                '''
            }
        }

        stage('Verify Rollout') {
            steps {
                // Fails the pipeline if the new pods do not become ready in time
                sh 'kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$K8S_NAMESPACE" --timeout=180s'
                // -o wide shows the image the Deployment is now running
                sh 'kubectl get deployment "$DEPLOYMENT_NAME" -n "$K8S_NAMESPACE" -o wide'
            }
        }
    }

    post {
        always {
            // Free disk space on the Jenkins instance
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
