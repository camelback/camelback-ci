#!/bin/bash

# Script to create Jenkins pipeline job with proper CSRF handling

JENKINS_URL="http://localhost:8080"
USERNAME="camelbot"
PASSWORD="jcrszVBcc122UdAgXoaH"
JOB_NAME="sample-pipeline"

echo "🔧 Creating Jenkins pipeline job: $JOB_NAME"

# Get CSRF token
echo "📋 Getting CSRF token..."
CSRF_HEADER=$(curl -s -u "$USERNAME:$PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=//crumbRequestField" | sed 's/<[^>]*>//g')
CSRF_VALUE=$(curl -s -u "$USERNAME:$PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=//crumb" | sed 's/<[^>]*>//g')

if [ -z "$CSRF_HEADER" ] || [ -z "$CSRF_VALUE" ]; then
    echo "❌ Failed to get CSRF token. Make sure Jenkins is running and accessible."
    exit 1
fi

echo "✅ CSRF token obtained: $CSRF_HEADER"

# Read the pipeline script
PIPELINE_SCRIPT=$(cat pipelines/sample-pipeline.groovy)

# Create job configuration XML
JOB_CONFIG=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job">
  <description>A sample pipeline demonstrating Jenkins CI/CD capabilities with agent execution</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers/>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script>$PIPELINE_SCRIPT</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
)

# Create the job
echo "🚀 Creating pipeline job..."
RESPONSE=$(curl -s -w "%{http_code}" -u "$USERNAME:$PASSWORD" \
    -H "Content-Type: application/xml" \
    -H "$CSRF_HEADER: $CSRF_VALUE" \
    -X POST \
    -d "$JOB_CONFIG" \
    "$JENKINS_URL/createItem?name=$JOB_NAME")

HTTP_CODE="${RESPONSE: -3}"
RESPONSE_BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Pipeline job '$JOB_NAME' created successfully!"
    echo ""
    echo "🌐 Access your pipeline at: $JENKINS_URL/job/$JOB_NAME"
    echo "🔨 To run the pipeline, click 'Build Now' in the Jenkins UI"
    echo ""
    echo "📋 Job Features:"
    echo "  • Runs on agent1"
    echo "  • Multi-stage build process"
    echo "  • Parallel testing"
    echo "  • Artifact archiving"
    echo "  • Environment checks"
    echo "  • Post-build actions"
elif [ "$HTTP_CODE" = "400" ] && echo "$RESPONSE_BODY" | grep -q "already exists"; then
    echo "ℹ️  Job '$JOB_NAME' already exists. Updating configuration..."
    
    # Update existing job
    UPDATE_RESPONSE=$(curl -s -w "%{http_code}" -u "$USERNAME:$PASSWORD" \
        -H "Content-Type: application/xml" \
        -H "$CSRF_HEADER: $CSRF_VALUE" \
        -X POST \
        -d "$JOB_CONFIG" \
        "$JENKINS_URL/job/$JOB_NAME/config.xml")
    
    UPDATE_CODE="${UPDATE_RESPONSE: -3}"
    if [ "$UPDATE_CODE" = "200" ]; then
        echo "✅ Pipeline job '$JOB_NAME' updated successfully!"
    else
        echo "❌ Failed to update job. HTTP Code: $UPDATE_CODE"
        echo "Response: ${UPDATE_RESPONSE%???}"
    fi
else
    echo "❌ Failed to create pipeline job. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  • Make sure Jenkins is running: docker-compose ps"
    echo "  • Check Jenkins logs: docker-compose logs jenkins"
    echo "  • Verify credentials and CSRF settings"
fi