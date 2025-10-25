# Jenkins Configuration Test Script

## Overview

The `test-jenkins.sh` script provides comprehensive testing for your Jenkins controller and agent configuration. It validates the entire setup from Docker containers to Jenkins functionality.

## What the Test Script Validates

### 1. Infrastructure Tests
- **Docker Daemon**: Verifies Docker is running and accessible
- **Docker Compose**: Confirms Docker Compose is available and working
- **Service Startup**: Tests that Jenkins controller and agent containers start successfully

### 2. Authentication & Security Tests
- **Admin Authentication**: Tests login with the `camelbot` admin user
- **Agent Authentication**: Verifies the `frank` agent user can authenticate
- **Role-Based Access**: Validates that role-based authorization is working

### 3. Configuration Tests
- **Configuration as Code (CasC)**: Ensures jenkins.yaml is loaded correctly
- **Security Realm**: Verifies user configuration from CasC
- **Plugin Installation**: Checks that all required plugins are installed:
  - configuration-as-code
  - docker-plugin
  - docker-workflow
  - blueocean
  - job-dsl
  - matrix-auth
  - role-strategy

### 4. Agent Connectivity Tests
- **Node Configuration**: Confirms agent1 and agent2 nodes are defined
- **Agent Connection**: Tests that agent1 can connect to the controller
- **Agent Status**: Monitors agent online/offline status

### 5. Job Execution Tests
- **Job Creation**: Creates a test job assigned to agent1
- **Job Execution**: Runs the job to verify agent can execute tasks
- **Build Results**: Validates successful job completion

## Usage Examples

```bash
# Run full test suite
./test-jenkins.sh

# Or use the Makefile
make test

# Quick test (skip job creation)
make test-quick

# View service logs
make logs

# Clean up containers and volumes
make clean
```

## Test Output

The script provides:
- ✅ **Colored output** for easy reading (green = pass, red = fail)
- 📊 **Progress tracking** with test counters
- 🔍 **Detailed error reporting** for failed tests
- 📋 **Summary report** showing passed/failed test counts
- 📝 **Service logs** when tests fail for troubleshooting

## Fixed Issues

The test script helped identify and fix several configuration issues:

1. **Agent Script Permissions**: Fixed `/agent.sh` execution permissions in Docker container
2. **Docker Compose Configuration**: Corrected volume mounts and secrets configuration
3. **Plugin Dependencies**: Added missing `role-strategy` plugin for role-based authorization
4. **Agent Startup Timing**: Added proper wait logic for Jenkins to be ready before agent connection

## Expected Results

When your Jenkins setup is working correctly, you should see:
- ✅ All containers start successfully
- ✅ Authentication works for both admin and agent users
- ✅ All required plugins are installed and loaded
- ✅ Agent nodes are configured and can connect
- ✅ Test jobs can be created and executed successfully on agents

## Troubleshooting

If tests fail, the script will:
- Show detailed error messages
- Display recent service logs
- Provide specific guidance on what failed
- Continue running other tests to give a complete picture

This comprehensive testing ensures your Jenkins CI/CD pipeline is ready for production use.