pipeline {
    agent {
        label 'agent1'
    }
    
    environment {
        BUILD_VERSION = "${BUILD_NUMBER}"
        PROJECT_NAME = 'camelback-ci-sample'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "Starting build ${BUILD_VERSION} for ${PROJECT_NAME}"
                echo "Running on agent: ${NODE_NAME}"
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
                    sh 'df -h'
                    echo "=== Memory Information ==="
                    sh 'cat /proc/meminfo | head -5'
                    echo "=== Java Version ==="
                    sh 'java -version || echo "Java not found"'
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
                        script {
                            try {
                                sh '''
                                    echo "Test suite: Unit Tests"
                                    echo "Running test_example_1... PASSED"
                                    echo "Running test_example_2... PASSED"
                                    echo "Running test_example_3... PASSED"
                                    echo "Unit tests completed successfully"
                                '''
                            } catch (Exception e) {
                                error "Unit tests failed: ${e.getMessage()}"
                            }
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        echo "Running integration tests..."
                        script {
                            try {
                                sh '''
                                    echo "Test suite: Integration Tests"
                                    echo "Testing API endpoints... PASSED"
                                    echo "Testing database connections... PASSED"
                                    echo "Integration tests completed successfully"
                                '''
                            } catch (Exception e) {
                                error "Integration tests failed: ${e.getMessage()}"
                            }
                        }
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
                        echo "Agent workspace: \$(pwd)" >> artifacts/app-${version}.txt
                        ls -la artifacts/
                    """
                }
                
                // Archive artifacts
                archiveArtifacts artifacts: 'artifacts/*', fingerprint: true, allowEmptyArchive: true
            }
        }
        
        stage('Deploy to Dev') {
            when {
                branch 'master'
            }
            steps {
                echo "Deploying to development environment..."
                script {
                    def deployTarget = 'dev-environment'
                    echo "Deployment target: ${deployTarget}"
                    sh '''
                        echo "Connecting to development server..."
                        echo "Uploading artifacts..."
                        echo "Restarting services..."
                        echo "Deployment completed successfully"
                    '''
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
            script {
                if (env.BRANCH_NAME == 'master') {
                    echo "Master branch build - ready for production deployment"
                }
            }
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
            script {
                try {
                    sh 'ls -la artifacts/ || echo "No artifacts directory found"'
                    sh 'rm -rf artifacts/* || echo "No artifacts to clean"'
                    echo "Cleanup completed successfully"
                } catch (Exception e) {
                    echo "Cleanup warning: ${e.getMessage()}"
                }
            }
        }
    }
}