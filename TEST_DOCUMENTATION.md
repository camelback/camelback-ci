# Jenkins Configuration Test Script

## Overview

The `test-jenkins.sh` script provides comprehensive testing for your Jenkins controller and agent configuration. It validates the entire setup from Docker containers to Jenkins functionality, with enhanced error handling and detailed diagnostics.

## What the Test Script Validates

### 1. Infrastructure Tests
- **Docker Daemon**: Verifies Docker is running and accessible
- **Docker Compose**: Confirms Docker Compose is available and working
- **Service Startup**: Tests that Jenkins controller and agent containers start successfully

### 2. Authentication & Security Tests
- **Admin Authentication**: Tests login with the `camelbot` admin user
- **Agent Authentication**: Verifies the `frank` agent user can authenticate
- **Role-Based Access**: Validates that role-based authorization is working
- **Session Management**: Tests `/me` endpoint for proper user session handling

### 3. Configuration Tests
- **Jenkins Initialization**: Checks if Jenkins has fully started and is in NORMAL mode
- **Configuration as Code (CasC)**: Ensures jenkins.yaml is loaded correctly
- **Security Realm**: Verifies user configuration from CasC
- **Authorization Strategy**: Tests role-based access control setup
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
- **Agent Status**: Monitors agent online/offline status with retry logic

### 5. Job Execution Tests
- **Job Creation**: Creates a test job assigned to agent1
- **Job Execution**: Runs the job to verify agent can execute tasks
- **Build Results**: Validates successful job completion

## Enhanced Error Handling

The test script now includes:

### Authentication Error Detection
- **AccessDeniedException**: Detects when `/me` endpoint returns access denied
- **Initialization Status**: Checks if Jenkins is fully initialized before testing authorization
- **Detailed Error Messages**: Provides specific error context and troubleshooting hints

### Timing and Retry Logic
- **Extended Wait Time**: Gives Jenkins 60 seconds to fully initialize (up from 30)
- **Agent Connection Retry**: Waits 30 seconds for agents to connect before marking as failed
- **Service Readiness**: Polls endpoints until services are ready or timeout

### Debug Information
- **Response Snippets**: Shows partial API responses when tests fail
- **Status Logging**: Displays Jenkins initialization mode and status
- **Error Context**: Provides specific error messages and suggested fixes

## Usage Examples

```bash
# Run full test suite (with extended wait times)
./test-jenkins.sh

# Or use the Makefile
make test

# Quick test (shorter timeouts, skip job creation)
make test-quick

# View service logs for troubleshooting
make logs

# Clean up containers and volumes
make clean
```

## Test Output

The script provides:
- ✅ **Colored output** for easy reading (green = pass, red = fail, blue = info)
- 📊 **Progress tracking** with test counters
- 🔍 **Detailed error reporting** for failed tests with context
- 📋 **Summary report** showing passed/failed test counts
- 📝 **Service logs** when tests fail for troubleshooting
- 🛠️ **Troubleshooting hints** for common issues

## Common Issues and Solutions

### AccessDeniedException on `/me` endpoint
This typically occurs when:
- **Jenkins still initializing**: Wait longer for CasC configuration to load
- **Security realm not configured**: Check jenkins.yaml syntax and plugin installation
- **User authentication issues**: Verify user credentials and permissions

**Solution**: The test now waits 60 seconds and provides detailed status information.

### Agent Connection Issues
- **Timing problems**: Agent tries to connect before Jenkins is ready
- **Network connectivity**: Docker networking issues between containers
- **Authentication failures**: Agent credentials not properly configured

**Solution**: Enhanced agent script with proper wait logic and connection retry.

### Plugin Installation Problems
- **Missing dependencies**: Some plugins require others to be installed first
- **Build failures**: Plugin download or installation errors during Docker build
- **Version conflicts**: Plugin version incompatibilities

**Solution**: Test script checks individual plugin installation and provides specific failure information.

## Fixed Issues

The test script helped identify and fix several configuration issues:

1. **Agent Script Permissions**: Fixed `/agent.sh` execution permissions in Docker container
2. **Docker Compose Configuration**: Corrected volume mounts and secrets configuration
3. **Plugin Dependencies**: Added missing `role-strategy` plugin for role-based authorization
4. **Agent Startup Timing**: Added proper wait logic for Jenkins to be ready before agent connection
5. **Authentication Flow**: Enhanced error detection for access denied scenarios
6. **Initialization Sequence**: Added checks for Jenkins initialization status

## Expected Results

When your Jenkins setup is working correctly, you should see:
- ✅ All containers start successfully
- ✅ Jenkins reaches NORMAL mode within timeout
- ✅ Authentication works for both admin and agent users
- ✅ All required plugins are installed and loaded
- ✅ CasC configuration is applied successfully
- ✅ Agent nodes are configured and can connect
- ✅ Test jobs can be created and executed successfully on agents
- ✅ Role-based authorization allows proper access control

## Troubleshooting

If tests fail, the script will:
- Show detailed error messages with context
- Display recent service logs automatically
- Provide specific guidance on what failed
- Show partial API responses for debugging
- Continue running other tests to give a complete picture
- Suggest common solutions for known issues

## Test Timing

- **Service Startup**: Up to 5 minutes timeout for Jenkins to be ready
- **Initialization Wait**: 60 seconds for CasC configuration to load
- **Agent Connection**: 30 seconds retry for agent to connect
- **Job Execution**: 20 seconds for test job to complete

This comprehensive testing ensures your Jenkins CI/CD pipeline is ready for production use with proper error handling and detailed diagnostics.