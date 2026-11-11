/*
 * Jenkinsfile — Production CI/CD Pipeline
 * ─────────────────────────────────────────────────────────────────────────────
 * Stages:
 *   1. Checkout
 *   2. Build & Test  (Maven, per service)
 *   3. SonarQube Code Analysis
 *   4. Docker Build  (per service)
 *   5. Push to ECR
 *   6. Update K8s manifests with new image tag
 *   7. Manual Approval Gate  (prod only)
 *   8. Deploy to EKS  (kubectl rollout)
 *   9. Smoke Test
 *  10. Slack Notifications
 *
 * Prerequisites — Jenkins credentials to create (Manage Jenkins → Credentials):
 *   • aws-jenkins-creds   : AWS credentials (kind: AWS Credentials plugin)
 *   • sonar-token         : SonarQube token  (kind: Secret text)
 *   • slack-webhook       : Slack webhook URL (kind: Secret text)
 * ─────────────────────────────────────────────────────────────────────────────
 */

pipeline {

  agent any

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timeout(time: 60, unit: 'MINUTES')
  }

  parameters {
    choice(
      name: 'DEPLOY_ENV',
      choices: ['dev', 'staging', 'prod'],
      description: 'Target environment'
    )
    booleanParam(
      name: 'RUN_TESTS',
      defaultValue: true,
      description: 'Run Maven unit tests'
    )
    booleanParam(
      name: 'RUN_SONAR',
      defaultValue: true,
      description: 'Run SonarQube analysis'
    )
    string(
      name: 'IMAGE_TAG',
      defaultValue: '',
      description: 'Optional Docker image tag override (default: BUILD_NUMBER)'
    )
  }

  environment {
    // ── AWS / ECR ─────────────────────────────────────────────────────────
    AWS_REGION      = 'ap-south-1'                                     // ← change to your region
    AWS_ACCOUNT_ID  = '392186013048'
    ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_BASE        = "${ECR_REGISTRY}/microservices"

    // ── EKS ───────────────────────────────────────────────────────────────
    EKS_CLUSTER_NAME = 'microservices-eks'                              // ← change to your EKS cluster name
    K8S_NAMESPACE    = 'microservices'

    // ── SonarQube ─────────────────────────────────────────────────────────
    SONAR_HOST_URL   = 'http://your-sonar-server:9000'                  // ← change to your SonarQube URL

    // ── Services ──────────────────────────────────────────────────────────
    SERVICES         = 'config-server eureka-server api-gateway user-service product-service order-service notification-service'

    // ── Image tag ─────────────────────────────────────────────────────────
    EFFECTIVE_TAG    = "${params.IMAGE_TAG ?: env.BUILD_NUMBER}"
  }

  stages {

    // ── 1. Checkout ───────────────────────────────────────────────────────
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.GIT_BRANCH_NAME  = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
          echo "Branch: ${env.GIT_BRANCH_NAME}  |  Commit: ${env.GIT_COMMIT_SHORT}  |  Tag: ${env.EFFECTIVE_TAG}"
        }
      }
    }

    // ── 2. Build & Test ───────────────────────────────────────────────────
    stage('Build & Test') {
      steps {
        script {
          def skipTests = params.RUN_TESTS ? '' : '-DskipTests'
          for (svc in env.SERVICES.split(' ')) {
            echo "▶ Building ${svc}..."
            sh "mvn -f ${svc}/pom.xml clean package ${skipTests} -B --no-transfer-progress"
          }
        }
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
        }
      }
    }

    // ── 3. SonarQube Analysis ─────────────────────────────────────────────
    stage('SonarQube Analysis') {
      when { expression { params.RUN_SONAR } }
      steps {
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          sh """
            mvn sonar:sonar \
              -Dsonar.host.url=${env.SONAR_HOST_URL} \
              -Dsonar.login=${SONAR_TOKEN} \
              -Dsonar.projectKey=microservices \
              -Dsonar.projectName=Microservices \
              -B --no-transfer-progress
          """
        }
      }
    }

    // ── 4. Docker Build ───────────────────────────────────────────────────
    stage('Docker Build') {
      steps {
        script {
          for (svc in env.SERVICES.split(' ')) {
            echo "🐳 Building Docker image for ${svc}..."
            sh "docker build -t ${env.ECR_BASE}/${svc}:${env.EFFECTIVE_TAG} ${svc}"
            sh "docker tag  ${env.ECR_BASE}/${svc}:${env.EFFECTIVE_TAG} ${env.ECR_BASE}/${svc}:latest"
          }
        }
      }
    }

    // ── 5. Push to ECR ────────────────────────────────────────────────────
    stage('Push to ECR') {
      steps {
        withCredentials([[
          $class           : 'AmazonWebServicesCredentialsBinding',
          credentialsId    : 'aws-jenkins-creds',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          sh """
            aws ecr get-login-password --region ${env.AWS_REGION} \
              | docker login --username AWS --password-stdin ${env.ECR_REGISTRY}
          """
          script {
            for (svc in env.SERVICES.split(' ')) {
              sh "docker push ${env.ECR_BASE}/${svc}:${env.EFFECTIVE_TAG}"
              sh "docker push ${env.ECR_BASE}/${svc}:latest"
              sh "docker rmi  ${env.ECR_BASE}/${svc}:${env.EFFECTIVE_TAG} ${env.ECR_BASE}/${svc}:latest || true"
            }
          }
        }
      }
    }

    // ── 6. Update Manifests ───────────────────────────────────────────────
    stage('Update K8s Manifests') {
      steps {
        sh "sed -i 's|REPLACE_IN_CI|${env.ECR_BASE}|g' deploy/eks/microservices.yaml"
      }
    }

    // ── 7. Production Approval ────────────────────────────────────────────
    stage('Approval — Production') {
      when { environment name: 'DEPLOY_ENV', value: 'prod' }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: "🚀 Deploy build #${env.BUILD_NUMBER} (tag: ${env.EFFECTIVE_TAG}) to PRODUCTION?", ok: 'Yes, Deploy!'
        }
      }
    }

    // ── 8. Deploy to EKS ──────────────────────────────────────────────────
    stage('Deploy to EKS') {
      steps {
        withCredentials([[
          $class           : 'AmazonWebServicesCredentialsBinding',
          credentialsId    : 'aws-jenkins-creds',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          sh "aws eks update-kubeconfig --region ${env.AWS_REGION} --name ${env.EKS_CLUSTER_NAME}"
          sh 'kubectl apply -f deploy/eks/platform-config.yaml'
          sh 'kubectl apply -f deploy/eks/microservices.yaml'
          script {
            for (svc in env.SERVICES.split(' ')) {
              sh "kubectl -n ${env.K8S_NAMESPACE} set image deployment/${svc} ${svc}=${env.ECR_BASE}/${svc}:${env.EFFECTIVE_TAG}"
              sh "kubectl -n ${env.K8S_NAMESPACE} rollout status deployment/${svc} --timeout=300s"
            }
          }
        }
      }
    }

    // ── 9. Smoke Test ─────────────────────────────────────────────────────
    stage('Smoke Test') {
      steps {
        withCredentials([[
          $class           : 'AmazonWebServicesCredentialsBinding',
          credentialsId    : 'aws-jenkins-creds',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          sh "kubectl -n ${env.K8S_NAMESPACE} get pods -o wide"
          sh "kubectl -n ${env.K8S_NAMESPACE} get services"
          sh "kubectl -n ${env.K8S_NAMESPACE} get ingress"
          script {
            def ingHost = sh(
              script: "kubectl -n ${env.K8S_NAMESPACE} get ingress api-gateway-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
              returnStdout: true
            ).trim()
            if (ingHost) {
              echo "✅ API Gateway: http://${ingHost}"
              sh "curl -sf http://${ingHost}/actuator/health || echo 'Health endpoint not yet ready'"
            } else {
              echo "⚠️  Ingress address not yet assigned — check AWS Load Balancer Controller"
            }
          }
        }
      }
    }

  } // end stages

  // ── Post Actions ──────────────────────────────────────────────────────────
  post {
    always {
      archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true, allowEmptyArchive: true
      cleanWs()
    }
    success {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
        sh """
          curl -s -X POST -H 'Content-type: application/json' \
          --data '{"text":"✅ *[${env.DEPLOY_ENV}]* Build #${env.BUILD_NUMBER} deployed. Tag: *${env.EFFECTIVE_TAG}*. Branch: ${env.GIT_BRANCH_NAME}"}' \
          ${SLACK_URL}
        """
      }
    }
    failure {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
        sh """
          curl -s -X POST -H 'Content-type: application/json' \
          --data '{"text":"❌ *[${env.DEPLOY_ENV}]* Build #${env.BUILD_NUMBER} FAILED. Branch: ${env.GIT_BRANCH_NAME}. See: ${env.BUILD_URL}"}' \
          ${SLACK_URL}
        """
      }
    }
  }

}
