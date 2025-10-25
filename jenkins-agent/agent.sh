#!/bin/bash
set -e

# Fetch the agent secret from the controller using the agent account
AGENT_SECRET=$(curl -u "$JENKINS_AGENT_USERNAME:$JENKINS_AGENT_PASSWORD" \
  "$JENKINS_URL/computer/agent1/slave-agent.jnlp" | grep -oP '(?<=<secret>).*(?=</secret>)')

# Connect to Jenkins as inbound agent
exec java -jar /usr/share/jenkins/agent.jar \
  -jnlpUrl "$JENKINS_URL/computer/agent1/slave-agent.jnlp" \
  -secret "$AGENT_SECRET" \
  -workDir "/home/jenkins/agent"
