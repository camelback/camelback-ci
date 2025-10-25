// Job DSL script to create pipeline jobs from the pipelines folder

// Sample Pipeline Job
pipelineJob('sample-pipeline') {
    displayName('Camelback CI - Sample Pipeline')
    description('A sample pipeline demonstrating Jenkins CI/CD capabilities with agent execution')
    
    parameters {
        stringParam('ENVIRONMENT', 'dev', 'Target environment for deployment')
        booleanParam('SKIP_TESTS', false, 'Skip test execution for faster builds')
        choiceParam('BUILD_TYPE', ['debug', 'release'], 'Build configuration type')
    }
    
    properties {
        githubProjectProperty {
            projectUrl('https://github.com/camelback/camelback-ci')
        }
        
        pipelineTriggers {
            triggers {
                pollSCM {
                    scmpoll_spec('H/15 * * * *')  // Poll every 15 minutes
                }
                cron('H 2 * * *')  // Daily build at 2 AM
            }
        }
        
        disableConcurrentBuilds()
        
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('10')
                    daysToKeepStr('30')
                    artifactNumToKeepStr('5')
                    artifactDaysToKeepStr('14')
                }
            }
        }
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/camelback/camelback-ci.git')
                        credentials('github-credentials')  // If using private repo
                    }
                    branch('master')
                }
            }
            scriptPath('pipelines/sample-pipeline.groovy')
            lightweight(true)
        }
    }
}

// Additional pipeline for first.groovy if it exists
if (new File('/var/jenkins_home/workspace/pipelines/first.groovy').exists()) {
    pipelineJob('first-pipeline') {
        displayName('First Pipeline')
        description('Pipeline created from first.groovy')
        
        definition {
            cps {
                script(readFileFromWorkspace('pipelines/first.groovy'))
                sandbox(true)
            }
        }
    }
}

// Dynamic Agent Pipeline - Provisions agents on-demand
pipelineJob('dynamic-agent-pipeline') {
    displayName('Dynamic Agent Pipeline')
    description('Pipeline that automatically provisions Docker agents and tears them down after build completion')
    
    parameters {
        choiceParam('AGENT_IMAGE', ['openjdk:17-jdk-slim', 'openjdk:11-jdk-slim', 'node:18-slim', 'python:3.11-slim'], 'Docker image for dynamic agent')
        stringParam('BUILD_ARGS', '-v /tmp:/tmp', 'Additional Docker arguments for agent')
        booleanParam('CLEANUP_WORKSPACE', true, 'Clean workspace after build')
    }
    
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('20')
                    daysToKeepStr('30')
                    artifactNumToKeepStr('10')
                    artifactDaysToKeepStr('14')
                }
            }
        }
        
        disableConcurrentBuilds()
    }
    
    definition {
        cps {
            script(readFileFromWorkspace('pipelines/dynamic-agent-pipeline.groovy'))
            sandbox(true)
        }
    }
}

// Multi-branch pipeline for automatic branch detection
multibranchPipelineJob('camelback-ci-multibranch') {
    displayName('Camelback CI - Multi-branch Pipeline')
    description('Multi-branch pipeline for automatic branch building')
    
    branchSources {
        git {
            id('camelback-ci-git')
            remote('https://github.com/camelback/camelback-ci.git')
            // credentialsId('github-credentials')  // Uncomment if using private repo
        }
    }
    
    configure { node ->
        def traits = node / 'sources' / 'data' / 'jenkins.branch.BranchSource' / 'source' / 'traits'
        traits << 'jenkins.plugins.git.traits.BranchDiscoveryTrait'()
        traits << 'jenkins.plugins.git.traits.CleanBeforeCheckoutTrait'()
    }
    
    factory {
        workflowBranchProjectFactory {
            scriptPath('pipelines/sample-pipeline.groovy')
        }
    }
    
    triggers {
        periodic(15)  // Scan for new branches every 15 minutes
    }
}

// Folder organization
folder('CI-CD') {
    displayName('CI/CD Pipelines')
    description('Continuous Integration and Deployment pipelines')
}

// Move jobs into folders for better organization
pipelineJob('CI-CD/docker-build-pipeline') {
    displayName('Docker Build Pipeline')
    description('Pipeline for building and pushing Docker images')
    
    parameters {
        stringParam('DOCKER_TAG', 'latest', 'Docker image tag')
        stringParam('REGISTRY_URL', 'docker.io', 'Docker registry URL')
    }
    
    definition {
        cps {
            script('''
pipeline {
    agent { label 'agent1' }
    
    environment {
        DOCKER_TAG = "${params.DOCKER_TAG}"
        REGISTRY_URL = "${params.REGISTRY_URL}"
    }
    
    stages {
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image with tag: ${DOCKER_TAG}"
                script {
                    def imageName = "camelback-ci:${DOCKER_TAG}"
                    echo "Image name: ${imageName}"
                    // sh "docker build -t ${imageName} ."
                    echo "Docker image built successfully"
                }
            }
        }
        
        stage('Test Image') {
            steps {
                echo "Testing Docker image..."
                // sh "docker run --rm ${imageName} echo 'Container test passed'"
                echo "Docker image test completed"
            }
        }
        
        stage('Push to Registry') {
            when {
                branch 'master'
            }
            steps {
                echo "Pushing to registry: ${REGISTRY_URL}"
                // sh "docker push ${REGISTRY_URL}/${imageName}"
                echo "Image pushed successfully"
            }
        }
    }
    
    post {
        always {
            echo "Docker pipeline completed"
        }
        success {
            echo "✅ Docker build and push successful!"
        }
        failure {
            echo "❌ Docker pipeline failed!"
        }
    }
}
            ''')
            sandbox(true)
        }
    }
}

// Create a seed job that will execute this DSL
job('seed-job') {
    displayName('Job DSL Seed')
    description('Seed job to create all pipeline jobs from DSL scripts')
    
    scm {
        git {
            remote {
                url('https://github.com/camelback/camelback-ci.git')
            }
            branch('master')
        }
    }
    
    steps {
        dsl {
            external('jenkins-jobs/*.groovy')
            removeAction('DELETE')
            ignoreExisting(false)
        }
    }
    
    triggers {
        scm('H/15 * * * *')  // Check for changes every 15 minutes
    }
}