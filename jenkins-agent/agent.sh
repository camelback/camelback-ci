#!/bin/bash
set -e

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
while ! curl -s -f "$JENKINS_URL/login" > /dev/null; do
    echo "Jenkins not ready yet, waiting..."
    sleep 10
done
echo "Jenkins is ready!"

# Fetch the agent secret from the controller using the agent account
echo "Fetching agent secret..."
AGENT_SECRET=$(curl -u "$JENKINS_AGENT_USERNAME:$JENKINS_AGENT_PASSWORD" \
  "$JENKINS_URL/computer/agent1/slave-agent.jnlp" | grep -oP '(?<=<secret>).*(?=</secret>)')

echo "Starting Jenkins agent..."
# Connect to Jenkins as inbound agent
exec java -jar /usr/share/jenkins/agent.jar \
  -jnlpUrl "$JENKINS_URL/computer/agent1/slave-agent.jnlp" \
  -secret "$AGENT_SECRET" \
  -workDir "/home/jenkins/agent"
