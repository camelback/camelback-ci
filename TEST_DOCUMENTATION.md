# Jenkins CI/CD Test Documentation

This document outlines the comprehensive testing strategy for the Camelback CI Jenkins environment, including traditional permanent agents and dynamic Docker agent provisioning.

## Test Categories

### 1. Infrastructure Tests
- Docker daemon availability
- Docker Compose functionality
- Service startup and health checks
- Network connectivity between services
- **Docker socket accessibility from Jenkins controller**
- **Docker CLI functionality within Jenkins container**

### 2. Authentication Tests
- Admin user login verification
- Agent user authentication
- CSRF token generation and validation
- Security realm configuration

### 3. Configuration Tests
- Jenkins initialization status
- Configuration as Code (CasC) loading
- Plugin installation verification (including docker-workflow)
- Tool configuration validation
- **Docker integration configuration**

### 4. Agent Tests
#### Permanent Agents
- Agent node configuration
- Agent connectivity status
- JNLP connection establishment
- Agent workspace setup

#### Dynamic Docker Agents
- **Docker image pulling capability**
- **Container provisioning and startup**
- **Agent lifecycle management (create → execute → destroy)**
- **Multi-environment support (Java, Node.js, Python)**
- **Resource cleanup verification**
- **Network connectivity between dynamic agents and controller**

### 5. Pipeline Tests
- Job creation capabilities
- Build triggering mechanisms
- Pipeline execution on permanent agents
- **Pipeline execution on dynamic Docker agents**
- **Cross-environment pipeline testing**
- Artifact generation and archival
- **Dynamic agent cleanup validation**