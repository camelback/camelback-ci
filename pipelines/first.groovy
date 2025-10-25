pipeline {
  agent {
    docker {
      image 'jenkins-agent:latest'
      args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
  }
  stages {
    stage('Build') {
      steps {
        sh 'make build'
      }
    }
  }
}
