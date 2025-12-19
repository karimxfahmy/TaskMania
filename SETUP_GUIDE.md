# Setup Guide 📖

Comprehensive setup and configuration guide for TaskMania System Monitor.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Advanced Setup](#advanced-setup)
5. [Production Deployment](#production-deployment)
6. [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disk**: 5GB free space
- **OS**: Linux, macOS, or Windows with WSL2
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Recommended Requirements
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disk**: 10GB free space (for historical data)
- **Network**: Stable connection for Docker image pulls

## Installation

### Step 1: Install Docker

#### Linux
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### macOS
Download and install [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)

#### Windows
Download and install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)

### Step 2: Install Docker Compose

Docker Compose is included with Docker Desktop. For Linux:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 3: Clone Repository

```bash
git clone <repository-url>
cd TaskMania
```

### Step 4: Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

## Configuration

### Monitor Configuration

Edit `config/monitor_config.conf`:

```bash
# Collection interval (seconds)
MONITOR_INTERVAL=5

# Data retention (days)
DATA_RETENTION_DAYS=7

# Enable/disable monitors
ENABLE_CPU=true
ENABLE_MEMORY=true
ENABLE_DISK=true
ENABLE_NETWORK=true
ENABLE_GPU=true

# Logging
LOG_LEVEL=INFO
```

### Alert Configuration

Edit `config/alert_config.conf`:

```bash
# CPU thresholds
CPU_THRESHOLD=80              # Usage percentage
LOAD_THRESHOLD=4.0            # Load per core
TEMP_THRESHOLD=80.0           # Temperature (Celsius)

# Memory thresholds
MEMORY_THRESHOLD=85           # Usage percentage
SWAP_THRESHOLD=70             # Swap usage percentage

# Disk thresholds
DISK_THRESHOLD=90             # Usage percentage

# Alert cooldown
ALERT_COOLDOWN=300            # Seconds between same alert type
```

### Port Configuration

Edit `docker-compose.yml` to change ports:

```yaml
services:
  web:
    ports:
      - "3000:80"    # Web dashboard
  api:
    ports:
      - "8000:8000"  # API server
  grafana:
    ports:
      - "3001:3000"  # Grafana
  influxdb:
    ports:
      - "8086:8086"  # InfluxDB
```

### Environment Variables

Create a `.env` file in the project root:

```bash
# Monitoring
MONITOR_INTERVAL=5
DATA_RETENTION_DAYS=7

# API
API_PORT=8000
DEBUG=false

# Database
INFLUXDB_DB=system_monitoring
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=changeme

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=changeme
```

## Advanced Setup

### Custom Data Storage

Mount external directories for persistent storage:

```yaml
services:
  monitor:
    volumes:
      - /your/custom/path/data:/app/data
      - /your/custom/path/logs:/app/logs
      - /your/custom/path/reports:/app/reports
```

### GPU Monitoring

For NVIDIA GPUs, add nvidia-docker support:

```yaml
services:
  monitor:
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
```

Then install nvidia-smi in the container or use the host's installation.

### Network Configuration

For custom networks:

```yaml
networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/16
```

### Resource Limits

Limit container resources:

```yaml
services:
  monitor:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Production Deployment

### Security Hardening

1. **Change Default Passwords**
   ```yaml
   environment:
     - INFLUXDB_ADMIN_PASSWORD=<strong-password>
     - GF_SECURITY_ADMIN_PASSWORD=<strong-password>
   ```

2. **Enable HTTPS**
   - Use a reverse proxy (nginx, traefik)
   - Configure SSL certificates
   - Update API proxy settings

3. **Restrict Network Access**
   ```yaml
   networks:
     monitoring:
       internal: true  # No external access
   ```

4. **Enable Authentication**
   - Add authentication to API endpoints
   - Configure Grafana auth providers
   - Use InfluxDB authentication

### Backup Strategy

1. **Automated Backups**
   ```bash
   # Backup script
   #!/bin/bash
   docker-compose exec influxdb influxd backup -portable /backup
   docker cp taskmania-influxdb:/backup ./backups/$(date +%Y%m%d)
   ```

2. **Data Export**
   ```bash
   # Export metrics
   docker-compose exec processor python3 /app/scripts/data_processor.py export
   ```

### Monitoring the Monitor

Set up external monitoring:
- Health checks
- Uptime monitoring
- Log aggregation
- Alerting to external systems

### Scaling

For multiple hosts:
1. Use remote InfluxDB
2. Deploy monitor on each host
3. Centralize API and web interface
4. Configure host tags in metrics

## Troubleshooting

### Container Issues

**Problem**: Container fails to start
```bash
# Check logs
docker-compose logs <service-name>

# Check container status
docker-compose ps

# Restart container
docker-compose restart <service-name>
```

**Problem**: Out of memory
```bash
# Check resource usage
docker stats

# Increase Docker memory limit in Docker Desktop settings
# Or add resource limits in docker-compose.yml
```

### Metrics Issues

**Problem**: No metrics collected
1. Check monitor logs: `docker-compose logs monitor`
2. Verify /proc and /sys are mounted
3. Check permissions

**Problem**: Metrics not updating
1. Check collection interval
2. Verify data directory is writable
3. Check disk space

### Network Issues

**Problem**: Can't access dashboard
1. Check if containers are running: `docker-compose ps`
2. Verify port mappings: `docker ps`
3. Check firewall rules
4. Test with curl: `curl http://localhost:3000`

**Problem**: API not responding
1. Check API logs: `docker-compose logs api`
2. Verify API is running: `curl http://localhost:8000/api/health`
3. Check network connectivity between containers

### Database Issues

**Problem**: InfluxDB not starting
1. Check data directory permissions
2. Verify disk space
3. Check InfluxDB logs: `docker-compose logs influxdb`

**Problem**: Data not persisting
1. Check volume mounts in docker-compose.yml
2. Verify volume exists: `docker volume ls`
3. Inspect volume: `docker volume inspect taskmania_influxdb-data`

### Performance Issues

**Problem**: High CPU usage
- Increase monitoring interval
- Reduce data retention
- Optimize queries

**Problem**: High memory usage
- Limit container memory
- Reduce metrics history
- Clean old data: `make clean-data`

**Problem**: Disk filling up
- Adjust data retention
- Enable automatic cleanup
- Archive old reports

## Support

For additional help:
- Check the [README.md](README.md)
- Review [CONTRIBUTING.md](CONTRIBUTING.md)
- Search existing issues
- Create a new issue with logs and details

---

Happy monitoring! 📊
