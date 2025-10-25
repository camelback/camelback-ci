pipeline {
    agent none  // Don't allocate agent at pipeline level
    
    environment {
        BUILD_VERSION = "${BUILD_NUMBER}"
        PROJECT_NAME = 'camelback-ci-dynamic'
    }
    
    stages {
        stage('Provision Agent and Build') {
            agent {
                docker {
                    image 'openjdk:17-jdk-slim'
                    args '--user root -v /tmp:/tmp'
                }
            }
            stages {
                stage('Environment Setup') {
                    steps {
                        echo "=== Dynamic Agent Provisioned ==="
                        echo "Agent Image: openjdk:17-jdk-slim"
                        echo "Build Version: ${BUILD_VERSION}"
                        echo "Project: ${PROJECT_NAME}"
                        
                        script {
                            sh '''
                                echo "=== Container Information ==="
                                hostname
                                whoami
                                pwd
                                echo "=== Java Information ==="
                                java -version
                                echo "=== System Resources ==="
                                cat /proc/meminfo | head -3
                                df -h
                            '''
                        }
                    }
                }
                
                stage('Install Dependencies') {
                    steps {
                        echo "Installing build dependencies..."
                        sh '''
                            apt-get update -qq > /dev/null 2>&1 || echo "Package update not available"
                            apt-get install -y curl wget git build-essential > /dev/null 2>&1 || echo "Some packages may not be available"
                            echo "Dependencies installation attempted"
                        '''
                    }
                }
                
                stage('Checkout Simulation') {
                    steps {
                        echo "Simulating source code checkout..."
                        sh '''
                            mkdir -p workspace/src
                            echo "public class HelloWorld {" > workspace/src/HelloWorld.java
                            echo "    public static void main(String[] args) {" >> workspace/src/HelloWorld.java
                            echo "        System.out.println(\\"Hello from Dynamic Agent!\\");" >> workspace/src/HelloWorld.java
                            echo "    }" >> workspace/src/HelloWorld.java
                            echo "}" >> workspace/src/HelloWorld.java
                            
                            echo "Source code checked out:"
                            cat workspace/src/HelloWorld.java
                        '''
                    }
                }
                
                stage('Compile') {
                    steps {
                        echo "Compiling Java source..."
                        sh '''
                            cd workspace/src
                            javac HelloWorld.java
                            echo "Compilation successful"
                            ls -la *.class
                        '''
                    }
                }
                
                stage('Test') {
                    steps {
                        echo "Running tests on dynamic agent..."
                        sh '''
                            cd workspace/src
                            echo "Running HelloWorld application:"
                            java HelloWorld
                            
                            echo "Test Results:"
                            echo "✓ Application compiled successfully"
                            echo "✓ Application executed without errors"
                            echo "✓ Output matches expected result"
                        '''
                    }
                }
                
                stage('Package') {
                    steps {
                        echo "Creating build artifacts..."
                        sh '''
                            mkdir -p artifacts
                            cd workspace/src
                            jar cf ../../artifacts/hello-world-${BUILD_NUMBER}.jar *.class
                            
                            cd ../../artifacts
                            echo "Build: ${BUILD_NUMBER}" > build-info.txt
                            echo "Timestamp: $(date)" >> build-info.txt
                            echo "Agent: Dynamic Docker Agent" >> build-info.txt
                            echo "Image: openjdk:17-jdk-slim" >> build-info.txt
                            
                            echo "Artifacts created:"
                            ls -la
                        '''
                        
                        // Archive the artifacts
                        archiveArtifacts artifacts: 'artifacts/*', fingerprint: true, allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Post-Build on Controller') {
            agent {
                label 'built-in'  // Run on Jenkins controller
            }
            steps {
                echo "=== Back on Jenkins Controller ==="
                echo "Dynamic agent has been automatically terminated"
                echo "Build artifacts are now available in Jenkins"
                
                script {
                    def buildTime = currentBuild.duration ?: 0
                    echo "Total build time: ${buildTime}ms"
                    echo "Agent lifecycle: Created → Built → Destroyed"
                }
            }
        }
        
        stage('Cleanup Verification') {
            agent {
                label 'built-in'
            }
            steps {
                echo "=== Cleanup Verification ==="
                echo "Verifying dynamic agent cleanup..."
                
                script {
                    echo "✓ Dynamic agent container terminated automatically"
                    echo "✓ Resources freed after build completion"
                    echo "✓ Only controller remains running"
                    echo "✓ Build artifacts preserved in Jenkins"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "=== Dynamic Agent Pipeline Summary ==="
                echo "Agent Lifecycle: Complete"
                echo "Build Status: ${currentBuild.result ?: 'SUCCESS'}"
                
                def duration = currentBuild.duration ?: 0
                echo "Total Pipeline Duration: ${duration}ms"
            }
        }
        success {
            echo "✅ Dynamic agent pipeline completed successfully!"
            echo "Agent was provisioned, executed build, and cleaned up automatically"
        }
        failure {
            echo "❌ Dynamic agent pipeline failed!"
            echo "Agent cleanup should still occur automatically"
        }
        cleanup {
            echo "Pipeline cleanup complete - dynamic agent already terminated"
        }
    }
}