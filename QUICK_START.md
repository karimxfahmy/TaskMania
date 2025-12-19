# Quick Start Guide 🚀

Get TaskMania up and running in 5 minutes!

## Prerequisites

- Docker (20.10 or higher)
- Docker Compose (2.0 or higher)
- 2GB RAM available
- 1GB disk space

## Installation Steps

### 1. Get the Code

```bash
git clone <repository-url>
cd TaskMania
```

### 2. Start the Application

**Option A: Using the setup script (Recommended)**
```bash
chmod +x setup.sh
./setup.sh
```

**Option B: Using Docker Compose**
```bash
docker-compose up -d
```

**Option C: Using Make**
```bash
make up
```

### 3. Access the Dashboard

Open your browser and navigate to:
- **Web Dashboard**: http://localhost:3000
- **API Server**: http://localhost:8000
- **Grafana**: http://localhost:3001 (login: admin/admin123)

## First Steps

### View Real-time Metrics

1. Open http://localhost:3000
2. You'll see real-time system metrics updating every 5 seconds
3. Monitor CPU, Memory, Disk, and Network statistics

### Check Alerts

The alert panel on the left shows any system warnings or critical events.

### Generate Reports

```bash
# Generate a 24-hour report
docker-compose exec processor python3 /app/scripts/data_processor.py report --hours 24

# View the report
open reports/latest_report.html
```

## Common Commands

```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Check status
docker-compose ps
```

## Customize Settings

### Change Alert Thresholds

Edit `config/alert_config.conf`:
```bash
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
```

### Change Monitoring Interval

Edit `config/monitor_config.conf`:
```bash
MONITOR_INTERVAL=5  # seconds
```

Then restart the monitor service:
```bash
docker-compose restart monitor
```

## Troubleshooting

### Services won't start?
```bash
# Check Docker is running
docker ps

# Check logs
docker-compose logs
```

### No metrics showing?
Wait 10-15 seconds for the first metrics to be collected.

### Port conflicts?
Edit `docker-compose.yml` to change ports:
```yaml
ports:
  - "3000:80"  # Change 3000 to another port
```

## Next Steps

- Read the full [README.md](README.md) for detailed information
- Check [SETUP_GUIDE.md](SETUP_GUIDE.md) for advanced configuration
- See [CONTRIBUTING.md](CONTRIBUTING.md) if you want to contribute

## Need Help?

Check the logs:
```bash
docker-compose logs -f monitor
docker-compose logs -f api
docker-compose logs -f web
```

---

That's it! You're now monitoring your system with TaskMania! 🎉
