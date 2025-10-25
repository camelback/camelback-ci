group "default" {
  targets = ["jenkins-controller", "jenkins-agent"]
}

target "jenkins-controller" {
  context = "./jenkins-controller"
  dockerfile = "Dockerfile"
  tags = ["camelback/jenkins-controller:latest"]
}

target "jenkins-agent" {
  context = "./jenkins-agent"
  dockerfile = "Dockerfile"
  tags = ["camelback/jenkins-agent:latest"]
}

