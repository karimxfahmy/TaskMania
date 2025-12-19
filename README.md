# TaskMania System Monitor 📊

A comprehensive, modern system monitoring solution that collects, analyzes, and visualizes hardware and software performance metrics in real-time.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Docker](https://img.shields.io/badge/docker-required-blue)

## 🌟 Features

### Monitoring Capabilities
- **CPU Monitoring**: Real-time CPU usage, load averages, and temperature tracking
- **Memory Tracking**: RAM and swap usage with detailed breakdowns
- **Disk Management**: Filesystem usage, SMART status, and I/O statistics
- **Network Analysis**: Interface statistics, bandwidth usage, and error tracking
- **GPU Detection**: Basic GPU identification (vendor-specific tools for detailed metrics)
- **System Information**: OS details, uptime, kernel version, and process count

### Key Components
- ✅ **Real-time Monitoring**: Collects metrics every 5 seconds
- 🚨 **Smart Alert System**: Configurable thresholds for critical events
- 📈 **Interactive Dashboard**: Modern React-based web interface
- 📊 **Historical Data**: Time-series storage with InfluxDB
- 📑 **Report Generation**: Automated HTML and Markdown reports
- 🐳 **Dockerized**: Fully containerized, no host dependencies
- 🎨 **Clean & Modern UI**: Beautiful, responsive design with real-time updates

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Web Interface                         │
│                   (React + Nginx)                        │
│                   Port: 3000                             │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                    API Server                            │
│                  (Python Flask)                          │
│                   Port: 8000                             │
└──────┬──────────────────────────────────────────────────┘
       │
       ├──────► Monitor Service (Bash) ──────► Data Files
       │
       ├──────► Alert Service (Bash) ─────────► Alerts
       │
       ├──────► Data Processor (Python) ──────► Reports
       │
       └──────► InfluxDB ──────────────────────► Time-series DB
                    │
                    ▼
               Grafana (Optional)
               Port: 3001
```

## 🚀 Quick Start

### Prerequisites
- Docker (20.10+)
- Docker Compose (2.0+)
- 2GB free RAM
- 1GB free disk space

### Installation

1. **Clone or download the repository**
   ```bash
   git clone <your-repo-url>
   cd TaskMania
   ```

2. **Run the setup script** (Linux/Mac)
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   Or use Docker Compose directly:
   ```bash
   docker-compose up -d
   ```

3. **Access the dashboard**
   - Web Dashboard: http://localhost:3000
   - API Docs: http://localhost:8000/api/health
   - Grafana: http://localhost:3001 (admin/admin123)

## 📖 Usage

### Using Make Commands

```bash
# Start all services
make up

# View logs
make logs

# Generate a report
make report

# Stop services
make down

# Clean up everything
make clean
```

### Manual Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart monitor

# Check service status
docker-compose ps
```

### Configuration

#### Alert Thresholds
Edit `config/alert_config.conf`:
```bash
CPU_THRESHOLD=80              # CPU usage percentage
MEMORY_THRESHOLD=85           # Memory usage percentage
DISK_THRESHOLD=90             # Disk usage percentage
TEMP_THRESHOLD=80.0           # CPU temperature in Celsius
```

#### Monitoring Interval
Edit `config/monitor_config.conf`:
```bash
MONITOR_INTERVAL=5            # Collection interval in seconds
```

## 📊 Dashboard Features

### Main Dashboard
- **Live Metrics**: Real-time CPU, memory, disk, and network statistics
- **Visual Indicators**: Color-coded progress bars (green/yellow/red)
- **Temperature Monitoring**: CPU temperature with emoji indicators
- **Network Status**: Interface status with traffic statistics

### Alert Panel
- **Real-time Alerts**: Automatic notification of critical events
- **Severity Levels**: INFO, WARNING, CRITICAL
- **Alert History**: View past alerts with timestamps
- **Expandable View**: Show more/less alerts

### System Info
- **Hardware Details**: CPU model, architecture, core count
- **OS Information**: Distribution, kernel version
- **Uptime Tracking**: System uptime display
- **Process Count**: Active process monitoring

## 🔧 API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/health` | Health check |
| `GET /api/metrics/latest` | Latest system metrics |
| `GET /api/metrics/history/<hours>` | Metrics history |
| `GET /api/alerts/recent` | Recent alerts |
| `GET /api/summary` | Statistical summary |
| `GET /api/reports/latest` | Latest HTML report |
| `GET /api/reports/list` | List all reports |

## 📝 Report Generation

### Automatic Reports
Reports are generated automatically every hour and stored in the `reports/` directory.

### Manual Report Generation
```bash
# Generate 24-hour report
docker-compose exec processor python3 /app/scripts/data_processor.py report --hours 24

# View latest report
open reports/latest_report.html
```

## 🐛 Troubleshooting

### Container Issues
```bash
# Check container logs
docker-compose logs monitor
docker-compose logs api

# Restart containers
docker-compose restart

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### No Metrics Appearing
1. Check if monitor container is running: `docker-compose ps`
2. View monitor logs: `docker-compose logs monitor`
3. Verify data directory: `ls -la data/`

### High Resource Usage
- Increase monitoring interval in `config/monitor_config.conf`
- Reduce data retention period
- Limit the number of metrics stored

## 🔒 Security Notes

- Default passwords are set in `docker-compose.yml`
- Change default credentials before production use
- API has no authentication by default (add as needed)
- InfluxDB and Grafana accessible only via Docker network

## 📦 Project Structure

```
TaskMania/
├── api_server.py              # Flask API server
├── docker-compose.yml         # Docker orchestration
├── Makefile                   # Build automation
├── requirements.txt           # Python dependencies
├── setup.sh                   # Setup script
├── config/                    # Configuration files
│   ├── alert_config.conf
│   └── monitor_config.conf
├── docker/                    # Dockerfiles
│   ├── Dockerfile.monitor
│   ├── Dockerfile.web
│   ├── Dockerfile.api
│   ├── Dockerfile.alerts
│   ├── Dockerfile.processor
│   ├── nginx.conf
│   └── grafana-provisioning/
├── scripts/                   # Monitoring scripts
│   ├── system_monitor.sh      # Main monitor (Bash)
│   ├── alert_system.sh        # Alert system (Bash)
│   ├── data_processor.py      # Data analysis (Python)
│   ├── generate_report.sh
│   └── cleanup.sh
├── web/                       # React dashboard
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── App.js
│       ├── components/
│       │   ├── Dashboard.js
│       │   ├── CPUCard.js
│       │   ├── MemoryCard.js
│       │   ├── DiskCard.js
│       │   ├── NetworkCard.js
│       │   ├── SystemInfo.js
│       │   └── AlertPanel.js
│       └── index.js
├── data/                      # Metrics storage
├── logs/                      # Application logs
└── reports/                   # Generated reports
```

## 🎯 Technical Details

### Technologies Used
- **Frontend**: React 18, Recharts, CSS3
- **Backend**: Python Flask, Bash
- **Database**: InfluxDB (time-series)
- **Visualization**: Grafana (optional)
- **Containerization**: Docker, Docker Compose
- **Web Server**: Nginx

### Metrics Collection
All metrics are collected using built-in Linux tools:
- `/proc/stat` - CPU statistics
- `/proc/meminfo` - Memory information
- `/proc/diskstats` - Disk I/O statistics
- `/proc/net/dev` - Network statistics
- `/sys/class/thermal` - Temperature sensors
- `df` - Filesystem usage

**No external dependencies required on the host system!**

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Karim Fahmy** – Developed as a personal project / for learning purposes

## 🙏 Acknowledgments

- Built with React, Flask, and Docker
- Uses InfluxDB for time-series data
- Grafana for advanced visualization
- Alpine Linux for minimal container size

---

**Happy Monitoring! 📊**
