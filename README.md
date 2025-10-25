# Camelback CI - Jenkins Controller & Agent Setup

A comprehensive Jenkins CI/CD setup using Docker Compose with Configuration as Code (CasC), featuring automated controller-agent architecture for scalable build environments.

## 🚀 Features

- **Jenkins Controller** with Configuration as Code (CasC)
- **Jenkins Agent** with automatic connection and Docker support
- **Pre-configured Plugins** for modern CI/CD workflows
- **Role-based Security** with predefined users and permissions
- **Automated Testing** with comprehensive validation script
- **Docker-based** for easy deployment and scaling

## 🏗️ Architecture

```
┌─────────────────────┐    ┌─────────────────────┐
│   Jenkins Controller│    │   Jenkins Agent     │
│   - Web UI (8080)   │◄──►│   - Build Executor  │
│   - Agent Port      │    │   - Docker Support  │
│   - CasC Config     │    │   - Auto-connect    │
└─────────────────────┘    └─────────────────────┘
```

## 📋 Prerequisites

- **Docker** and **Docker Compose**
- **Host Machine**: Windows 11 with WSL (Ubuntu 24.04) or Linux
- **Ports**: 8080 (Jenkins UI) and 50000 (Agent communication)

## 🚀 Quick Start

### 1. Clone and Start Services

```bash
git clone <repository-url>
cd camelback-ci

# Start Jenkins services
docker-compose up -d

# Or use the Makefile
make test
```

### 2. Access Jenkins

- **URL**: http://localhost:8080
- **Admin User**: `camelbot`
- **Password**: Check `secrets/camelback_admin.txt`

### 3. Verify Setup

```bash
# Run comprehensive tests
./test-jenkins.sh

# Or quick test
make test-quick
```

## 📁 Project Structure

```
camelback-ci/
├── jenkins-controller/          # Controller configuration
│   ├── Dockerfile              # Controller Docker image
│   ├── jenkins.yaml            # Configuration as Code (CasC)
│   └── plugins.txt             # Required plugins list
├── jenkins-agent/              # Agent configuration  
│   ├── Dockerfile              # Agent Docker image
│   └── agent.sh                # Agent connection script
├── pipelines/                  # Pipeline definitions
│   └── first.groovy           # Sample pipeline
├── secrets/                    # Credentials and secrets
│   └── camelback_admin.txt    # Admin password
├── docker-compose.yml          # Service orchestration
├── test-jenkins.sh            # Comprehensive test suite
├── Makefile                   # Build and test commands
└── TEST_DOCUMENTATION.md      # Detailed testing guide
```

## 🔧 Configuration

### Jenkins Controller

- **Base Image**: `jenkins/jenkins:lts-jdk17`
- **Configuration**: Via `jenkins.yaml` (CasC)
- **Plugins**: Auto-installed from `plugins.txt`
- **Security**: Role-based with predefined users

### Jenkins Agent

- **Base Image**: `jenkins/inbound-agent:jdk17`
- **Connection**: Automatic via JNLP
- **Tools**: Docker support, curl
- **Authentication**: Username/password based

### Users & Permissions

| User | Role | Permissions |
|------|------|-------------|
| `camelbot` | Admin | Full administrative access |
| `frank` | Agent | Agent connection and build execution |

### Installed Plugins

- **configuration-as-code**: CasC support
- **docker-plugin**: Docker integration
- **docker-workflow**: Docker pipeline support
- **blueocean**: Modern UI experience
- **job-dsl**: Pipeline as Code
- **matrix-auth**: Role-based authorization
- **role-strategy**: Advanced role management

## 🧪 Testing

### Comprehensive Test Suite

The project includes a robust testing framework:

```bash
# Full test suite (recommended)
./test-jenkins.sh

# Quick connectivity test
./test-jenkins.sh quick

# View service logs
./test-jenkins.sh logs

# Clean up everything
./test-jenkins.sh cleanup
```

### Test Coverage

- ✅ Docker daemon and Compose availability
- ✅ Service startup and health checks
- ✅ Authentication for admin and agent users
- ✅ Configuration as Code (CasC) loading
- ✅ Plugin installation verification
- ✅ Agent node configuration and connectivity
- ✅ Job creation and execution on agents

### Expected Results

When working correctly:
- All containers start successfully
- Jenkins reaches NORMAL mode
- Both users can authenticate
- Agents connect and go online
- Test jobs execute successfully

## 🛠️ Development Commands

### Using Makefile

```bash
make help          # Show available commands
make setup         # Make test script executable
make test          # Run full test suite
make test-quick    # Run quick tests
make logs          # Show service logs
make clean         # Stop and clean up
```

### Using Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild images
docker-compose build --no-cache
```

## 🐛 Troubleshooting

### Common Issues

1. **AccessDeniedException on `/me` endpoint**
   - Wait longer for Jenkins to fully initialize
   - Check CasC configuration syntax
   - Verify plugin installation

2. **Agent connection failures**
   - Ensure Jenkins is fully started before agent attempts connection
   - Check network connectivity between containers
   - Verify agent credentials

3. **Plugin installation errors**
   - Check plugin dependencies
   - Verify plugin versions compatibility
   - Review build logs for specific errors

### Debug Commands

```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs jenkins
docker-compose logs agent1

# Test connectivity
curl http://localhost:8080/login
```

## 📈 Scaling

### Adding More Agents

1. **Update docker-compose.yml**:
```yaml
agent2:
  build:
    context: ./jenkins-agent
  depends_on:
    - jenkins
  environment:
    - JENKINS_URL=http://jenkins:8080
    - JENKINS_AGENT_USERNAME=frank
    - JENKINS_AGENT_PASSWORD=agentpass
```

2. **Update jenkins.yaml**:
```yaml
nodes:
  - permanent:
      name: agent2
      launcher: inbound
      remoteFS: /home/jenkins/agent
```

### Production Considerations

- Use external volumes for persistent data
- Implement proper secret management
- Configure backup strategies
- Set up monitoring and alerting
- Use HTTPS with proper certificates

## 📚 Additional Resources

- **Jenkins Configuration as Code**: [Official Documentation](https://github.com/jenkinsci/configuration-as-code-plugin)
- **Jenkins Docker Images**: [Official Repository](https://github.com/jenkinsci/docker)
- **Pipeline Documentation**: [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.