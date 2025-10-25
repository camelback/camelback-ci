FROM jenkins/inbound-agent:jdk17
USER root
RUN apt-get update && apt-get install -y curl
COPY agent.sh /agent.sh
RUN chmod +x /agent.sh
USER jenkins
ENTRYPOINT ["/agent.sh"]
