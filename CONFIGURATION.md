# Jenkins CI/CD Configuration Documentation

## Overview

This repository contains a complete Jenkins CI/CD environment using Docker Compose with a controller-agent architecture. The setup includes automated configuration, security, and pipeline capabilities.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Jenkins        │    │  Jenkins        │    │  Dynamic Docker │
│  Controller     │◄──►│  Agent1         │    │  Agents         │
│  (Port 8080)    │    │  (JNLP/WebSocket│    │  (On-Demand)    │
│  + Docker CLI   │    └─────────────────┘    └─────────────────┘
└─────────────────┘             │                       ▲
         │                      │                       │
         ▼                      ▼                       │
┌─────────────────┐    ┌─────────────────┐             │
│  Docker Volume  │    │  Jenkins        │             │
│  jenkins-data   │    │  Agent2         │             │
└─────────────────┘    │  (Configured)   │◄────────────┘
                       └─────────────────┘
                       
┌──────────────────────────────────────────────────────────┐
│  Docker Host Engine (Shared Socket)                     │
│  - Manages Dynamic Agent Containers                     │
│  - Automatic Provisioning & Cleanup                    │
│  - Multi-Environment Support (Java/Node/Python)        │
└──────────────────────────────────────────────────────────┘
```

## Components

### 1. Jenkins Controller (`jenkins-controller/`)

**Base Image**: `jenkins/jenkins:lts-jdk17`

**Key Features**:
- Configuration as Code (CasC) for automated setup
- Pre-installed plugins for CI/CD workflows
- Security configuration with matrix-based authorization
- CSRF protection enabled
- Blue Ocean UI for modern pipeline visualization
- **Docker CLI Integration** for dynamic agent provisioning
- **Root User Access** for Docker socket management
- **Dynamic Agent Support** with automatic lifecycle management

**Docker Integration**:
- Docker CLI installed in controller container
- Docker socket mounted from host (`/var/run/docker.sock`)
- Automatic Docker image pulling and management
- Support for multiple agent environments (Java, Node.js, Python)

**Configuration Files**:
- `Dockerfile`: Custom Jenkins image with plugins, configuration, and Docker CLI
- `jenkins.yaml`: CasC configuration defining users, security, agents, and executors
- `plugins.txt`: List of required Jenkins plugins including docker-workflow
- `init.groovy`: Initialization script for additional setup

### 2. Jenkins Agent (`jenkins-agent/`)

**Base Image**: `jenkins/inbound-agent:jdk17`

**Connection Method**: JNLP with WebSocket support

**Key Features**:
- Automatic connection to Jenkins controller
- Retry logic for robust connectivity
- Proper secret-based authentication
- Work directory management

**Configuration Files**:
- `Dockerfile`: Custom agent image with curl and connection script
- `agent.sh`: Connection script with retry logic and proper authentication

### 3. Pipeline Definitions (`pipelines/`)

**Available Pipelines**:
- `sample-pipeline.groovy`: Full CI/CD pipeline with multiple stages
- `sample-pipeline-controller.groovy`: Controller-optimized pipeline
- `first.groovy`: Basic hello world pipeline

### 4. Job Definitions (`jenkins-jobs/`)

**Job Configuration**:
- `pipeline-jobs.groovy`: Job DSL script for creating pipeline jobs

## Configuration Details

### Security Configuration

**Authentication**: Local security realm with predefined users
- **Admin User**: `camelbot` (full administrative access)
- **Agent User**: `frank` (agent connection permissions)

**Authorization**: Matrix-based security model
- Administrators have full access
- Authenticated users have read access
- Agent users have specific connection permissions

## Dynamic Agent Configuration

**Dynamic Agent Provisioning**: Jenkins can automatically provision Docker-based agents on-demand

**Key Features**:
- **On-Demand Provisioning**: Agents created only when needed for builds
- **Automatic Cleanup**: Agents destroyed immediately after build completion
- **Multiple Environments**: Different Docker images per pipeline
- **Resource Efficient**: No idle agent containers consuming resources
- **Clean Builds**: Fresh environment for every execution

**Available Agent Images**:
- `openjdk:17-jdk-slim`: Java 17 development environment
- `openjdk:11-jdk-slim`: Java 11 development environment  
- `node:18-slim`: Node.js 18 development environment
- `python:3.11-slim`: Python 3.11 development environment

**Usage Example**:
```groovy
pipeline {
    agent none
    
    stages {
        stage('Build') {
            agent {
                docker {
                    image 'openjdk:17-jdk-slim'
                    args '--user root -v /tmp:/tmp'
                }
            }
            steps {
                sh 'java -version'
                // Build steps here - agent auto-destroyed after
            }
        }
    }
}
```

**Benefits**:
- Zero permanent agent resource consumption
- Guaranteed clean build environments
- Scalable execution (multiple dynamic agents simultaneously)
- No manual agent lifecycle management
- Automatic Docker image management

### Agent Configuration

**Agent Nodes**:
- `agent1`: Primary build agent (configured and connected)
- `agent2`: Secondary agent (configured but offline)

**Connection Details**:
- **Protocol**: JNLP4 with WebSocket tunnel
- **Authentication**: Secret-based using 64-character JNLP secrets
- **Work Directory**: `/home/jenkins/agent`
- **Labels**: `agent1`, `linux`, `docker`

### Plugin Ecosystem

**Core Plugins**:
- `configuration-as-code`: Automated Jenkins configuration
- `job-dsl`: Programmatic job creation
- `matrix-auth`: Role-based access control
- `docker-plugin`: Docker integration
- `docker-workflow`: Docker pipeline steps

**Pipeline Plugins**:
- `blueocean`: Modern pipeline UI
- `pipeline-stage-view`: Visual pipeline representation
- `workflow-aggregator`: Core pipeline functionality

**SCM Plugins**:
- `git`: Git repository integration
- `github`: GitHub integration
- `github-branch-source`: GitHub branch discovery

## Directory Structure

```
camelback-ci/
├── jenkins-controller/          # Controller configuration
│   ├── Dockerfile              # Controller image definition
│   ├── jenkins.yaml            # CasC configuration
│   ├── plugins.txt             # Required plugins list
│   ├── init.groovy             # Initialization script
│   └── plugins/                # Pre-downloaded plugin files
├── jenkins-agent/              # Agent configuration
│   ├── Dockerfile              # Agent image definition
│   └── agent.sh                # Connection script
├── jenkins-jobs/               # Job definitions
│   └── pipeline-jobs.groovy    # Job DSL scripts
├── pipelines/                  # Pipeline definitions
│   ├── sample-pipeline.groovy  # Full CI/CD pipeline
│   ├── sample-pipeline-controller.groovy
│   └── first.groovy
├── secrets/                    # Secret files
│   └── camelbot_admin.txt      # Admin password
├── docker-compose.yml          # Service orchestration
├── test-jenkins.sh             # Comprehensive test suite
└── CONFIGURATION.md            # This documentation
```

## Environment Variables

### Controller Environment
```yaml
JAVA_OPTS: -Djenkins.install.runSetupWizard=false
CASC_JENKINS_CONFIG: /usr/share/jenkins/ref/jenkins.yaml
# Docker integration enabled via mounted socket
# User: root (for Docker access)
```

### Agent Environment (Permanent Agents)
```yaml
JENKINS_URL: http://jenkins:8080
JENKINS_AGENT_USERNAME: frank
JENKINS_AGENT_PASSWORD: agentpass
```

### Dynamic Agent Environment (Automatic)
```yaml
# Managed automatically by Jenkins Docker plugin
# No manual configuration required
# Inherits controller network and Docker access
# Temporary containers with isolated workspaces
```

## Network Configuration

**Services**:
- **Jenkins Controller**: `jenkins:8080` (internal), `localhost:8080` (external)
- **Jenkins Agent1**: `agent1` (internal network only)
- **Dynamic Agents**: Auto-managed containers on shared Docker network

**Volumes**:
- `jenkins-data`: Persistent Jenkins home directory
- `./jenkins-controller`: Controller configuration mount
- `/var/run/docker.sock`: Docker socket for dynamic agent management

**Docker Integration**:
- Shared Docker daemon between host and Jenkins controller
- Dynamic agent containers on same network as controller
- Automatic image pulling and container lifecycle management
- Isolated workspaces for each dynamic agent execution

**Secrets**:
- `jenkins_admin_password`: Admin user password from file

## Usage Instructions

### Starting the Environment

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f jenkins
docker-compose logs -f agent1
```

### Accessing Jenkins

**Web Interface**: http://localhost:8080

**Default Credentials**:
- Username: `camelbot`
- Password: Contents of `secrets/camelbot_admin.txt`

### Running Tests

```bash
# Execute comprehensive test suite
./test-jenkins.sh

# Test dynamic agent functionality specifically
./test-dynamic-agent.sh
```

**Test Coverage**:
- Docker setup validation
- Service startup verification
- Authentication testing
- Plugin installation checks
- Agent connectivity validation
- Job creation and execution testing
- **Dynamic agent provisioning and cleanup testing**
- **Docker integration validation**
- **Multi-environment agent testing**

### Creating New Pipelines

#### Traditional Agent Pipelines
1. **Add Pipeline File**: Create `.groovy` file in `pipelines/` directory
2. **Update Job DSL**: Modify `jenkins-jobs/pipeline-jobs.groovy`
3. **Restart Services**: `docker-compose restart jenkins`

#### Dynamic Agent Pipelines
1. **Use Docker Agent Syntax**: No additional configuration required
```groovy
pipeline {
    agent {
        docker {
            image 'openjdk:17-jdk-slim'
            args '--user root -v /tmp:/tmp'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'java -version'
                // Agent auto-destroyed after pipeline
            }
        }
    }
}
```

2. **Available Agent Images**:
   - `openjdk:17-jdk-slim`, `openjdk:11-jdk-slim` (Java)
   - `node:18-slim`, `node:16-slim` (Node.js)
   - `python:3.11-slim`, `python:3.9-slim` (Python)
   - Any public Docker image

3. **Test Pipeline**: Use existing `dynamic-agent-pipeline` or `advanced-dynamic-agent`

## Troubleshooting

### Common Issues

**Agent Connection Failures**:
- Check agent logs: `docker-compose logs agent1`
- Verify secret extraction in agent script
- Ensure Jenkins is fully initialized before agent starts

**Dynamic Agent Issues**:
- Check Docker availability: `docker-compose exec jenkins docker --version`
- Verify Docker socket mount: `docker-compose exec jenkins ls -la /var/run/docker.sock`
- Check image availability: `docker-compose exec jenkins docker images`
- Monitor agent provisioning: Jenkins UI → Build Logs

**Docker Integration Problems**:
- Ensure Jenkins runs as root user for Docker access
- Verify Docker socket permissions on host
- Check container network connectivity
- Pull required images manually if needed: `docker pull openjdk:17-jdk-slim`

**CSRF Protection Errors**:
- Use proper CSRF tokens for API calls
- Consider using API tokens instead of username/password

**Plugin Installation Issues**:
- Verify plugin compatibility with Jenkins LTS version
- Check plugin dependencies in `plugins.txt`
- Ensure docker-workflow plugin is installed

**Authentication Problems**:
- Verify secret file permissions and content
- Check CasC configuration syntax in `jenkins.yaml`

### Debugging Commands

```bash
# Check agent status
curl -s -u "camelbot:PASSWORD" "http://localhost:8080/computer/api/json"

# Get CSRF token
curl -s -u "camelbot:PASSWORD" "http://localhost:8080/crumbIssuer/api/json"

# View Jenkins logs
docker-compose logs -f jenkins

# Test Docker integration
docker-compose exec jenkins docker --version
docker-compose exec jenkins docker ps
docker-compose exec jenkins docker images

# Test dynamic agent functionality
./test-dynamic-agent.sh

# Monitor dynamic agent provisioning
docker ps -a | grep -E "(openjdk|node|python)"

# Check Docker socket access
docker-compose exec jenkins ls -la /var/run/docker.sock

# Rebuild services
docker-compose build --no-cache
docker-compose up -d
```

## Security Considerations

### Access Control
- Matrix-based authorization with principle of least privilege
- Separate accounts for admin and agent operations
- CSRF protection enabled for all operations

### Secrets Management
- Admin password stored in external file
- Agent secrets dynamically generated and retrieved
- No hardcoded credentials in configuration files

### Network Security
- Internal Docker network for service communication
- Only controller exposed to host network
- Agent connections use encrypted WebSocket tunnels

## Monitoring and Maintenance

### Health Checks
- Jenkins controller health endpoint: `/login`
- Agent connectivity via computer API
- Build queue monitoring through Blue Ocean

### Backup Considerations
- Jenkins home directory persisted in Docker volume
- Configuration stored in version-controlled files
- Job definitions maintained as code

### Updates and Upgrades
- Plugin updates managed through `plugins.txt`
- Jenkins version controlled via Docker image tag
- Configuration changes applied through CasC

## Performance Optimization

### Resource Allocation
- **Controller**: 2GB RAM recommended minimum (3GB+ for dynamic agents)
- **Permanent Agent**: 1GB RAM per concurrent build
- **Dynamic Agents**: 512MB-1GB RAM per container (scales automatically)
- **Disk space**: 15GB minimum for workspace, artifacts, and Docker images
- **Docker Images**: Pre-pull commonly used images to reduce startup time

### Dynamic Agent Optimization
- Pre-pull base images: `docker pull openjdk:17-jdk-slim node:18-slim python:3.11-slim`
- Use slim image variants for faster provisioning
- Configure agent args for optimal resource usage
- Monitor Docker daemon resource consumption

### Scaling Considerations
- **Permanent Agents**: Additional agents via docker-compose configuration
- **Dynamic Agents**: Unlimited scaling based on Docker host resources
- Agent labels used for job targeting
- Parallel build execution supported (both permanent and dynamic)
- Dynamic agents provide better resource utilization than permanent agents

## Integration Points

### Version Control
- Git repositories supported out of the box
- GitHub integration for webhooks and PR builds
- Branch-based pipeline triggering

### Docker Integration
- Docker-in-Docker capabilities
- Container-based build environments
- Image building and publishing workflows

### Notification Systems
- Email notifications configurable
- Slack integration available via plugins
- Custom webhook endpoints supported

---

**Last Updated**: October 25, 2025
**Jenkins Version**: LTS JDK17
**Docker Compose Version**: 3.x