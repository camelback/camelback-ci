FROM jenkins/inbound-agent:jdk17
USER root
RUN apt-get update && apt-get install -y curl
USER jenkins
COPY agent.sh /agent.sh
ENTRYPOINT ["/agent.sh"]
