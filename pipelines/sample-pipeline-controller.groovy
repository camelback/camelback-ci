pipeline {
    agent any  // This will run on any available agent, including the Jenkins controller
    
    environment {
        BUILD_VERSION = "${BUILD_NUMBER}"
        PROJECT_NAME = 'camelback-ci-sample'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "Starting build ${BUILD_VERSION} for ${PROJECT_NAME}"
                echo "Running on agent: ${NODE_NAME}"
                echo "Jenkins URL: ${JENKINS_URL}"
                echo "Workspace: ${WORKSPACE}"
            }
        }
        
        stage('Environment Check') {
            steps {
                script {
                    echo "=== Environment Information ==="
                    sh 'pwd'
                    sh 'whoami'
                    sh 'hostname'
                    sh 'date'
                    echo "=== System Information ==="
                    sh 'uname -a'
                    sh 'java -version'
                    echo "=== Available agents ==="
                    // Check available nodes
                    def jenkins = Jenkins.getInstance()
                    for (node in jenkins.getNodes()) {
                        echo "Agent: ${node.getNodeName()} - Online: ${!node.toComputer().isOffline()}"
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                echo "Building ${PROJECT_NAME}..."
                script {
                    def buildStart = new Date()
                    echo "Build started at: ${buildStart}"
                    
                    // Simulate build process
                    sh 'echo "Compiling source code..."'
                    sleep 2
                    sh 'echo "Running unit tests..."'
                    sleep 1
                    sh 'echo "Creating artifacts..."'
                    
                    def buildEnd = new Date()
                    echo "Build completed at: ${buildEnd}"
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "Running unit tests..."
                        sh '''
                            echo "Test suite: Unit Tests"
                            echo "Running test_example_1... PASSED"
                            echo "Running test_example_2... PASSED"
                            echo "Running test_example_3... PASSED"
                            echo "Unit tests completed successfully"
                        '''
                    }
                }
                stage('Integration Tests') {
                    steps {
                        echo "Running integration tests..."
                        sh '''
                            echo "Test suite: Integration Tests"
                            echo "Testing API endpoints... PASSED"
                            echo "Testing database connections... PASSED"
                            echo "Integration tests completed successfully"
                        '''
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo "Packaging application..."
                script {
                    def version = "${BUILD_VERSION}"
                    echo "Creating package version: ${version}"
                    sh """
                        mkdir -p artifacts
                        echo "Application package v${version}" > artifacts/app-${version}.txt
                        echo "Build timestamp: \$(date)" >> artifacts/app-${version}.txt
                        echo "Build node: ${NODE_NAME}" >> artifacts/app-${version}.txt
                        ls -la artifacts/
                    """
                }
                
                // Archive artifacts
                archiveArtifacts artifacts: 'artifacts/*', fingerprint: true
            }
        }
        
        stage('Agent Troubleshooting') {
            steps {
                echo "=== Agent Connection Troubleshooting ==="
                script {
                    def jenkins = Jenkins.getInstance()
                    def agent1 = jenkins.getNode('agent1')
                    if (agent1) {
                        echo "Agent1 found in configuration"
                        def computer = agent1.toComputer()
                        echo "Agent1 offline: ${computer.isOffline()}"
                        if (computer.isOffline()) {
                            echo "Agent1 offline cause: ${computer.getOfflineCause()}"
                        }
                    } else {
                        echo "Agent1 not found in Jenkins configuration"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline execution completed"
            script {
                def duration = currentBuild.duration / 1000
                echo "Total build time: ${duration} seconds"
            }
        }
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Note: This pipeline ran on the Jenkins controller since agent1 was offline"
        }
        failure {
            echo "❌ Pipeline failed!"
            script {
                echo "Build failed at stage: ${env.STAGE_NAME}"
                echo "Please check the logs and fix the issues"
            }
        }
        unstable {
            echo "⚠️ Pipeline completed with warnings"
        }
        cleanup {
            echo "Performing cleanup..."
            sh 'rm -rf artifacts/* || true'
        }
    }
}