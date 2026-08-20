pipeline {

    agent any

    environment {
        AWS_REGION = 'ap-south-1'

        EKS_CLUSTER_NAME = 'shopnow-eks'

        ECR_FRONTEND = 'shopnow-frontend'
        ECR_BACKEND  = 'shopnow-backend'
        ECR_ADMIN    = 'shopnow-admin'

        K8S_NAMESPACE = 'shopnow'

        IMAGE_TAG = "v${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Application') {
            parallel {

                stage('Validate Frontend') {
                    steps {
                        dir('frontend') {
                            sh '''
                                npm ci --no-audit --prefer-offline
                                CI=true npm test -- --watchAll=false --passWithNoTests
                            '''
                        }
                    }
                }

                stage('Validate Admin') {
                    steps {
                        dir('admin') {
                            sh '''
                                npm ci --no-audit --prefer-offline
                                CI=true npm test -- --watchAll=false --passWithNoTests
                            '''
                        }
                    }
                }

                stage('Validate Backend') {
                    steps {
                        dir('backend') {
                            sh '''
                                npm ci --no-audit --prefer-offline
                                node --check server.js
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    set -e

                    docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} ./frontend
                    docker build -t ${ECR_BACKEND}:${IMAGE_TAG} ./backend
                    docker build -t ${ECR_ADMIN}:${IMAGE_TAG} ./admin
                '''
            }
        }

	stage('Security Scan') {
    	    steps {
              	sh '''
            	    echo "Running Trivy security scans..."
            	    echo "HIGH/CRITICAL findings are reported for remediation."
            	    echo "Security gate is non-blocking for this capstone demonstration."

            	    trivy image --severity HIGH,CRITICAL \
              	      ${ECR_FRONTEND}:${IMAGE_TAG} || true

            	    trivy image --severity HIGH,CRITICAL \
              	      ${ECR_BACKEND}:${IMAGE_TAG} || true

            	    trivy image --severity HIGH,CRITICAL \
              	      ${ECR_ADMIN}:${IMAGE_TAG} || true
        	'''
    	    }
	}

        stage('Authenticate with ECR') {
            steps {
                sh '''
                    set -e

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                      --query Account \
                      --output text)

                    ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                    aws ecr get-login-password \
                      --region ${AWS_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Push Images to ECR') {
            steps {
                sh '''
                    set -e

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                      --query Account \
                      --output text)

                    ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                    docker tag \
                      ${ECR_FRONTEND}:${IMAGE_TAG} \
                      ${ECR_REGISTRY}/${ECR_FRONTEND}:${IMAGE_TAG}

                    docker tag \
                      ${ECR_BACKEND}:${IMAGE_TAG} \
                      ${ECR_REGISTRY}/${ECR_BACKEND}:${IMAGE_TAG}

                    docker tag \
                      ${ECR_ADMIN}:${IMAGE_TAG} \
                      ${ECR_REGISTRY}/${ECR_ADMIN}:${IMAGE_TAG}

                    docker push \
                      ${ECR_REGISTRY}/${ECR_FRONTEND}:${IMAGE_TAG}

                    docker push \
                      ${ECR_REGISTRY}/${ECR_BACKEND}:${IMAGE_TAG}

                    docker push \
                      ${ECR_REGISTRY}/${ECR_ADMIN}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -e

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                      --query Account \
                      --output text)

                    ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${EKS_CLUSTER_NAME}

		    kubectl get namespace ${K8S_NAMESPACE}


                    helm upgrade --install shopnow \
                      ./helm/shopnow \
                      --namespace ${K8S_NAMESPACE} \
                      --set frontend.image.repository=${ECR_REGISTRY}/${ECR_FRONTEND} \
                      --set frontend.image.tag=${IMAGE_TAG} \
                      --set backend.image.repository=${ECR_REGISTRY}/${ECR_BACKEND} \
                      --set backend.image.tag=${IMAGE_TAG} \
                      --set admin.image.repository=${ECR_REGISTRY}/${ECR_ADMIN} \
                      --set admin.image.tag=${IMAGE_TAG} \
                      --wait \
                      --timeout 10m
                '''
            }
        }

        stage('Verify Rollout') {
            steps {
                sh '''
                    set -e

                    kubectl rollout status \
                      deployment/shopnow-frontend \
                      -n ${K8S_NAMESPACE} \
                      --timeout=5m

                    kubectl rollout status \
                      deployment/shopnow-backend \
                      -n ${K8S_NAMESPACE} \
                      --timeout=5m

                    kubectl rollout status \
                      deployment/shopnow-admin \
                      -n ${K8S_NAMESPACE} \
                      --timeout=5m

                    kubectl rollout status \
                      deployment/shopnow-mongodb \
                      -n ${K8S_NAMESPACE} \
                      --timeout=5m
                '''
            }
        }

        stage('Verify Health and Autoscaling') {
            steps {
                sh '''
                    set -e

                    echo "=== Pods ==="
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide

                    echo "=== Services ==="
                    kubectl get services -n ${K8S_NAMESPACE}

                    echo "=== Ingress ==="
                    kubectl get ingress -n ${K8S_NAMESPACE}

                    echo "=== Horizontal Pod Autoscalers ==="
                    kubectl get hpa -n ${K8S_NAMESPACE}

                    echo "=== Deployment Status ==="
                    kubectl get deployments -n ${K8S_NAMESPACE}

                    echo "=== Backend Health ==="
                    kubectl run shopnow-health-check \
                      --rm \
                      --restart=Never \
                      --image=curlimages/curl:8.10.1 \
                      --command -- \
                      curl --fail --silent \
                      http://backend:5000/api/health

                    echo "Application health verification completed successfully."
                '''
            }
        }
    }

    post {

        success {
            echo "ShopNow deployment completed successfully."
            echo "Application version: ${IMAGE_TAG}"
        }

        failure {
            echo "ShopNow pipeline failed."
        }

        always {
            sh 'docker system prune -f || true'
        }
    }
}
