pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'DEPLOY_ENV', choices: ['dev', 'staging', 'prod'], description: 'Target Kubernetes environment')
    booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run Maven tests before packaging')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional image tag override (default: BUILD_NUMBER)')
  }

  environment {
    AWS_REGION = 'ap-south-1'
    EKS_CLUSTER_NAME = 'microservices-eks'
    K8S_NAMESPACE = 'microservices'
    ECR_REGISTRY = 'YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com'
    SERVICES = 'config-server eureka-server api-gateway user-service product-service order-service notification-service'
    EFFECTIVE_TAG = "${params.IMAGE_TAG ?: env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build and Test') {
      steps {
        script {
          def runTestsFlag = params.RUN_TESTS ? '' : '-DskipTests'
          for (svc in env.SERVICES.split(' ')) {
            sh "mvn -f ${svc}/pom.xml clean package ${runTestsFlag}".trim()
          }
        }
      }
    }

    stage('Docker Build') {
      steps {
        script {
          for (svc in env.SERVICES.split(' ')) {
            sh "docker build -t ${env.ECR_REGISTRY}/${svc}:${env.EFFECTIVE_TAG} ${svc}"
          }
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-creds'
        ]]) {
          sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_REGISTRY}"
          script {
            for (svc in env.SERVICES.split(' ')) {
              sh "docker push ${env.ECR_REGISTRY}/${svc}:${env.EFFECTIVE_TAG}"
            }
          }
        }
      }
    }

    stage('Approve Production') {
      when {
        environment name: 'DEPLOY_ENV', value: 'prod'
      }
      steps {
        input message: 'Approve deployment to production?', ok: 'Deploy'
      }
    }

    stage('Deploy to EKS') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-creds'
        ]]) {
          sh "aws eks update-kubeconfig --region ${env.AWS_REGION} --name ${env.EKS_CLUSTER_NAME}"
          sh 'kubectl apply -f deploy/eks/platform-config.yaml'
          sh 'kubectl apply -f deploy/eks/microservices.yaml'
          script {
            for (svc in env.SERVICES.split(' ')) {
              sh "kubectl -n ${env.K8S_NAMESPACE} set image deployment/${svc} ${svc}=${env.ECR_REGISTRY}/${svc}:${env.EFFECTIVE_TAG}"
              sh "kubectl -n ${env.K8S_NAMESPACE} rollout status deployment/${svc} --timeout=240s"
            }
          }
        }
      }
    }

    stage('Smoke Test') {
      when {
        anyOf {
          environment name: 'DEPLOY_ENV', value: 'dev'
          environment name: 'DEPLOY_ENV', value: 'staging'
        }
      }
      steps {
        sh "kubectl -n ${env.K8S_NAMESPACE} get pods -o wide"
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
    }
    success {
      echo "Deployment completed with image tag: ${env.EFFECTIVE_TAG}"
    }
    failure {
      echo 'Pipeline failed. Inspect build logs and rollout status for details.'
    }
  }
}
