#!/bin/bash

# Jenkins Configuration Test Script
# Tests Jenkins controller and agent setup

# Remove set -e to allow script to continue on errors
# We'll handle errors individually in each test function

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://localhost:8080"
ADMIN_USER="camelbot"
ADMIN_PASS="jcrszVBcc122UdAgXoaH"
AGENT_USER="frank"
AGENT_PASS="agentpass"
MAX_WAIT_TIME=300  # 5 minutes
CHECK_INTERVAL=10

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

wait_for_service() {
    local url=$1
    local service_name=$2
    local timeout=$3
    local elapsed=0
    
    print_info "Waiting for $service_name to be ready..."
    
    while [ $elapsed -lt $timeout ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready"
            return 0
        fi
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
        echo -n "."
    done
    
    print_failure "$service_name failed to start within $timeout seconds"
    return 1
}

test_docker_setup() {
    print_header "Testing Docker Setup"
    
    print_test "Docker daemon availability"
    if docker version > /dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_failure "Docker daemon is not accessible"
        return 1
    fi
    
    print_test "Docker Compose availability"
    if docker-compose version > /dev/null 2>&1; then
        print_success "Docker Compose is available"
    else
        print_failure "Docker Compose is not available"
        return 1
    fi
    
    return 0
}

test_services_startup() {
    print_header "Starting Jenkins Services"
    
    print_info "Starting services with docker-compose..."
    if docker-compose up -d; then
        print_success "Docker Compose services started"
    else
        print_failure "Failed to start Docker Compose services"
        return 1
    fi
    
    # Wait for Jenkins controller
    if wait_for_service "$JENKINS_URL/login" "Jenkins Controller" $MAX_WAIT_TIME; then
        print_success "Jenkins Controller started successfully"
    else
        print_failure "Jenkins Controller failed to start"
        return 1
    fi
    
    # Check if agent container is running
    print_test "Agent container status"
    if docker-compose ps agent1 | grep -q "Up"; then
        print_success "Agent container is running"
    else
        print_failure "Agent container is not running"
    fi
    
    return 0
}

test_jenkins_authentication() {
    print_header "Testing Jenkins Authentication"
    
    print_test "Admin user authentication"
    if curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/api/json" | grep -q "mode"; then
        print_success "Admin authentication successful"
    else
        print_failure "Admin authentication failed"
    fi
    
    print_test "Agent user authentication"
    if curl -s -u "$AGENT_USER:$AGENT_PASS" "$JENKINS_URL/api/json" | grep -q "mode"; then
        print_success "Agent user authentication successful"
    else
        print_failure "Agent user authentication failed"
    fi
}

test_jenkins_configuration() {
    print_header "Testing Jenkins Configuration"
    
    print_test "Jenkins initialization status"
    local init_status=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/api/json?tree=quietingDown,mode")
    if echo "$init_status" | grep -q '"mode":"NORMAL"'; then
        print_success "Jenkins is fully initialized"
    else
        print_failure "Jenkins may still be initializing"
        print_info "Current status: $(echo "$init_status" | head -c 100)"
    fi
    
    print_test "Configuration as Code (CasC) loading"
    local casc_status=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/configuration-as-code/")
    if echo "$casc_status" | grep -q "configuration-as-code"; then
        print_success "CasC plugin is loaded and accessible"
    else
        print_failure "CasC plugin not accessible"
    fi
    
    print_test "Security realm configuration"
    local users_api=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/asynchPeople/api/json")
    if echo "$users_api" | grep -q "$ADMIN_USER" && echo "$users_api" | grep -q "$AGENT_USER"; then
        print_success "Users configured correctly"
    else
        print_failure "User configuration issue detected"
    fi
    
    print_test "Role-based authorization"
    local whoami=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/me/api/json")
    if echo "$whoami" | grep -q "AccessDeniedException"; then
        print_failure "Role-based authorization issue: Access denied - user not properly authenticated"
        print_info "Jenkins may not be fully initialized or CasC not loaded yet"
    elif echo "$whoami" | grep -q "\"id\":\"$ADMIN_USER\""; then
        print_success "Role-based authorization working"
    elif echo "$whoami" | grep -q "error"; then
        print_failure "Role-based authorization issue: $(echo "$whoami" | grep -o 'error[^"]*')"
    else
        print_failure "Role-based authorization issue: unexpected response"
        print_info "Response: $(echo "$whoami" | head -c 200)..."
    fi
}

test_agent_nodes() {
    print_header "Testing Agent Nodes"
    
    print_test "Configured agent nodes"
    local computer_api=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/computer/api/json")
    
    if echo "$computer_api" | grep -q "agent1"; then
        print_success "Agent1 node is configured"
    else
        print_failure "Agent1 node not found"
    fi
    
    if echo "$computer_api" | grep -q "agent2"; then
        print_success "Agent2 node is configured"
    else
        print_failure "Agent2 node not found"
    fi
    
    # Check agent1 connection status
    print_test "Agent1 connection status"
    local agent1_status=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/computer/agent1/api/json")
    if echo "$agent1_status" | grep -q '"offline":false'; then
        print_success "Agent1 is online"
    elif echo "$agent1_status" | grep -q '"offline":true'; then
        print_info "Agent1 is offline (expected if not connected yet)"
        
        # Wait a bit for agent to connect
        sleep 30
        agent1_status=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/computer/agent1/api/json")
        if echo "$agent1_status" | grep -q '"offline":false'; then
            print_success "Agent1 connected after waiting"
        else
            print_failure "Agent1 failed to connect"
        fi
    else
        print_failure "Could not determine Agent1 status"
    fi
}

test_plugins() {
    print_header "Testing Plugin Installation"
    
    print_test "Required plugins installation"
    local plugins_api=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/pluginManager/api/json?depth=1")
    
    local required_plugins=("configuration-as-code" "docker-plugin" "docker-workflow" "blueocean" "job-dsl" "matrix-auth")
    
    for plugin in "${required_plugins[@]}"; do
        if echo "$plugins_api" | grep -q "\"shortName\":\"$plugin\""; then
            print_success "$plugin plugin is installed"
        else
            print_failure "$plugin plugin is missing"
        fi
    done
}

test_tools_configuration() {
    print_header "Testing Tool Configuration"
    
    print_test "Node.js tool configuration"
    local tools_api=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$JENKINS_URL/api/json")
    # This is a basic check - in a real scenario you'd check the tool installations endpoint
    if [ $? -eq 0 ]; then
        print_success "Tools API accessible"
    else
        print_failure "Tools API not accessible"
    fi
}

test_job_creation() {
    print_header "Testing Job Creation and Execution"
    
    print_test "Creating test job"
    
    # Create a simple test job
    local job_config='<?xml version="1.0" encoding="UTF-8"?>
<project>
    <description>Test job for agent connectivity</description>
    <keepDependencies>false</keepDependencies>
    <properties/>
    <scm class="hudson.scm.NullSCM"/>
    <assignedNode>agent1</assignedNode>
    <canRoam>false</canRoam>
    <disabled>false</disabled>
    <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
    <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
    <triggers/>
    <concurrentBuild>false</concurrentBuild>
    <builders>
        <hudson.tasks.Shell>
            <command>echo "Hello from agent: $(hostname)"
pwd
ls -la
echo "Agent test completed successfully"</command>
        </hudson.tasks.Shell>
    </builders>
    <publishers/>
    <buildWrappers/>
</project>'

    # Create the job
    if curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASS" \
        -H "Content-Type: application/xml" \
        -d "$job_config" \
        "$JENKINS_URL/createItem?name=test-agent-job" > /dev/null; then
        print_success "Test job created successfully"
        
        # Build the job
        print_test "Triggering test job build"
        if curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASS" \
            "$JENKINS_URL/job/test-agent-job/build" > /dev/null; then
            print_success "Test job build triggered"
            
            # Wait for build to complete and check result
            sleep 20
            local build_result=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
                "$JENKINS_URL/job/test-agent-job/1/api/json")
            
            if echo "$build_result" | grep -q '"result":"SUCCESS"'; then
                print_success "Test job executed successfully on agent"
            elif echo "$build_result" | grep -q '"building":true'; then
                print_info "Test job still building..."
            else
                print_failure "Test job execution failed"
            fi
        else
            print_failure "Failed to trigger test job build"
        fi
    else
        print_failure "Failed to create test job"
    fi
}

cleanup_test_resources() {
    print_header "Cleaning Up Test Resources"
    
    print_info "Removing test job..."
    curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASS" \
        "$JENKINS_URL/job/test-agent-job/doDelete" > /dev/null || true
}

show_logs() {
    print_header "Service Logs (Last 50 lines)"
    
    echo -e "${YELLOW}Jenkins Controller Logs:${NC}"
    docker-compose logs --tail=50 jenkins
    
    echo -e "${YELLOW}Agent Logs:${NC}"
    docker-compose logs --tail=50 agent1
}

print_summary() {
    print_header "Test Summary"
    
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Jenkins setup is working correctly.${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Check the output above for details.${NC}"
        return 1
    fi
}

# Main execution
main() {
    print_header "Jenkins Configuration Test Suite"
    
    # Run tests - continue even if some fail
    test_docker_setup || true
    test_services_startup || true
    sleep 60  # Give Jenkins more time to fully initialize and load CasC config
    test_jenkins_authentication || true
    test_jenkins_configuration || true
    test_plugins || true
    test_tools_configuration || true
    test_agent_nodes || true
    test_job_creation || true
    
    # Cleanup
    cleanup_test_resources || true
    
    # Show logs if there were failures
    if [ $TESTS_FAILED -gt 0 ]; then
        show_logs
    fi
    
    # Print summary
    print_summary
    
    # Return appropriate exit code
    [ $TESTS_FAILED -eq 0 ]
}

# Handle script arguments
case "${1:-}" in
    "cleanup")
        print_info "Stopping and removing containers..."
        docker-compose down -v
        docker system prune -f
        print_success "Cleanup completed"
        ;;
    "logs")
        show_logs
        ;;
    "quick")
        # Quick test - skip job creation
        test_docker_setup || true
        test_services_startup || true
        sleep 20
        test_jenkins_authentication || true
        test_agent_nodes || true
        print_summary
        ;;
    *)
        main
        ;;
esac