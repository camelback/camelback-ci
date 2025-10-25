docker network create jenkins


docker buildx bake

Host Machine:
- windows 11
- using WSL (Ubuntu24.04)
Concept:
- jenkins-controller
    - plugins.txt - used during provisioning of controller defining the necessary Jenkins plugins
    - jenkins.yaml - JCaaC used during provisioning
    - Users:
        - camelbot JENKINS_ADMIN_ID JENKINS_ADMIN_PASSWORD
- jenkins-agent
    - 
- pipelines
    - default pre-installed jenkins pipeline