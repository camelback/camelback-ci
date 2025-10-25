FROM jenkins/jenkins:lts-jdk17

USER root

# Install Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Add jenkins user to docker group
RUN groupadd -g 999 docker || true
RUN usermod -aG docker jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/init.groovy

# Install plugins to the ref directory
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Ensure plugins are copied to jenkins_home at runtime by setting up proper permissions
RUN chown -R jenkins:jenkins /usr/share/jenkins/ref/

USER jenkins

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG="/usr/share/jenkins/ref/jenkins.yaml"
