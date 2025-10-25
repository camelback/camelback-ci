#!/bin/bash
set -e

# Jenkins Agent Connection Script with proper secret handling
JENKINS_URL="http://jenkins:8080"
AGENT_NAME="agent1"
AGENT_WORKDIR="/home/jenkins/agent"

echo "Starting Jenkins Agent: $AGENT_NAME"
echo "Jenkins URL: $JENKINS_URL"

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
while ! curl -s -f "$JENKINS_URL/login" > /dev/null; do
    echo "Jenkins not ready yet, waiting..."
    sleep 10
done
echo "Jenkins is ready!"

# Create work directory
mkdir -p "$AGENT_WORKDIR"

# Function to get agent secret from JNLP file
get_agent_secret() {
    local secret=$(curl -s -u "camelbot:jcrszVBcc122UdAgXoaH" \
        "$JENKINS_URL/computer/$AGENT_NAME/jenkins-agent.jnlp" | \
        grep -oP '<argument>\K[a-f0-9]{64}(?=</argument>)')
    echo "$secret"
}

# Retry logic for connecting to Jenkins
max_retries=10
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    echo "Attempt $((retry_count + 1)) to connect to Jenkins..."
    
    # Get the current agent secret
    AGENT_SECRET=$(get_agent_secret)
    
    if [ -n "$AGENT_SECRET" ] && [ ${#AGENT_SECRET} -eq 64 ]; then
        echo "Got agent secret: ${AGENT_SECRET:0:16}..."
        
        # Connect to Jenkins using WebSocket
        echo "Connecting agent $AGENT_NAME to Jenkins..."
        exec java -jar /usr/share/jenkins/agent.jar \
            -url "$JENKINS_URL" \
            -secret "$AGENT_SECRET" \
            -name "$AGENT_NAME" \
            -workDir "$AGENT_WORKDIR" \
            -webSocket
    else
        echo "Failed to get valid agent secret, retrying in 15 seconds..."
        sleep 15
    fi
    
    retry_count=$((retry_count + 1))
done

echo "Failed to connect after $max_retries attempts"
exit 1
