# TaskMania Architecture Overview

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│                     http://localhost:3000                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEB CONTAINER (Nginx)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              React Dashboard (Static Files)               │  │
│  │  • Real-time metrics display                              │  │
│  │  • Alert panel                                            │  │
│  │  • System information                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                             │ /api/* → proxy                     │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API CONTAINER (Flask)                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   REST API Server                         │  │
│  │  GET /api/metrics/latest                                  │  │
│  │  GET /api/alerts/recent                                   │  │
│  │  GET /api/summary                                         │  │
│  │  GET /api/reports/latest                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│                  Reads from shared volumes                       │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SHARED VOLUMES                                │
│  ┌──────────────┬──────────────┬──────────────┐                │
│  │  /app/data   │  /app/logs   │  /app/reports│                │
│  │              │              │              │                │
│  │ metrics_*.   │ monitor.log  │ report_*.    │                │
│  │   json       │ alerts.log   │   html       │                │
│  │ alerts.jsonl │              │              │                │
│  │ summaries    │              │              │                │
│  └──────────────┴──────────────┴──────────────┘                │
│         ▲              ▲              ▲                          │
│         │              │              │                          │
└─────────┼──────────────┼──────────────┼──────────────────────────┘
          │              │              │
    ┌─────┴──────┬───────┴────┬─────────┴────────┐
    │            │            │                  │
    ▼            ▼            ▼                  ▼
┌────────┐  ┌─────────┐  ┌──────────┐  ┌───────────────┐
│MONITOR │  │ ALERTS  │  │PROCESSOR │  │  INFLUXDB     │
│CONTAINER  │CONTAINER│  │CONTAINER │  │  WRITER       │
└────────┘  └─────────┘  └──────────┘  └───────────────┘
    │            │            │                  │
    │  Bash      │  Bash      │  Python          │  Python
    │  Script    │  Script    │  Script          │  Script
    │            │            │                  │
    ▼            ▼            ▼                  ▼
┌────────────────────────────────────────────────────────┐
│              HOST SYSTEM MONITORING                     │
│  /proc/stat      - CPU statistics                      │
│  /proc/meminfo   - Memory information                  │
│  /proc/diskstats - Disk I/O                            │
│  /proc/net/dev   - Network statistics                  │
│  /sys/class/*    - Hardware sensors                    │
└────────────────────────────────────────────────────────┘
                              │
                              │ Writes to
                              ▼
                    ┌──────────────────┐
                    │   INFLUXDB       │
                    │  (Time-series    │
                    │   Database)      │
                    └──────────────────┘
                              │
                              │ Queries
                              ▼
                    ┌──────────────────┐
                    │    GRAFANA       │
                    │  (Visualization) │
                    │  Port: 3001      │
                    └──────────────────┘
```

## Component Details

### 1. Monitor Container
**Purpose**: Collect system metrics

**Technology**: Alpine Linux + Bash
**Script**: `scripts/system_monitor.sh`

**Functions**:
- Collects metrics every 5 seconds (configurable)
- Reads from `/proc` and `/sys` filesystems
- Uses only built-in Linux tools (no dependencies!)
- Outputs JSON to shared volume
- Maintains symlink to latest metrics

**Metrics Collected**:
- CPU: usage, load, temperature, model
- Memory: RAM, swap, buffers, cache
- Disk: usage, I/O statistics
- Network: interface stats, bandwidth
- System: uptime, processes, OS info

### 2. Alert Container
**Purpose**: Monitor thresholds and generate alerts

**Technology**: Alpine Linux + Bash
**Script**: `scripts/alert_system.sh`

**Functions**:
- Reads latest metrics every 30 seconds
- Compares against configured thresholds
- Generates alerts with severity levels
- Implements cooldown to prevent spam
- Logs alerts to shared volume

**Alert Types**:
- CPU: high usage, high load, high temperature
- Memory: high RAM usage, high swap usage
- Disk: high disk usage per filesystem
- Network: interface errors

### 3. Processor Container
**Purpose**: Data analysis and report generation

**Technology**: Python 3.11
**Script**: `scripts/data_processor.py`

**Functions**:
- Aggregates metrics every hour
- Calculates statistics (avg, min, max)
- Generates HTML reports
- Creates JSON summaries
- Cleans up old data

**Outputs**:
- `latest_summary.json` - Statistical summary
- `latest_report.html` - Visual HTML report
- Historical summaries and reports

### 4. API Container
**Purpose**: Serve data to web interface

**Technology**: Python Flask + Flask-CORS
**Script**: `api_server.py`

**Endpoints**:
```
GET /api/health              - Health check
GET /api/metrics/latest      - Latest metrics
GET /api/metrics/history/:h  - Historical data
GET /api/alerts/recent       - Recent alerts
GET /api/summary             - Statistical summary
GET /api/reports/latest      - Latest HTML report
GET /api/reports/list        - List all reports
GET /api/system/info         - System information
```

**Port**: 8000

### 5. Web Container
**Purpose**: User interface

**Technology**: React 18 + Nginx

**Components**:
- `App.js` - Main application
- `Dashboard.js` - Main dashboard layout
- `CPUCard.js` - CPU metrics display
- `MemoryCard.js` - Memory metrics display
- `DiskCard.js` - Disk metrics display
- `NetworkCard.js` - Network metrics display
- `SystemInfo.js` - System information panel
- `AlertPanel.js` - Alerts display

**Features**:
- Auto-refresh every 5 seconds
- Color-coded status indicators
- Responsive design
- Real-time updates
- Interactive UI

**Port**: 3000

### 6. InfluxDB Container
**Purpose**: Time-series data storage

**Technology**: InfluxDB 1.8

**Functions**:
- Stores historical metrics
- Provides time-series queries
- Data source for Grafana
- Efficient storage and retrieval

**Port**: 8086
**Database**: system_monitoring

### 7. Grafana Container (Optional)
**Purpose**: Advanced visualization

**Technology**: Grafana Latest

**Features**:
- Custom dashboards
- Advanced queries
- Alerting capabilities
- User management

**Port**: 3001
**Credentials**: admin/admin123

## Data Flow

### Metrics Collection Flow
```
1. Monitor Script runs every 5 seconds
2. Reads /proc, /sys filesystems
3. Formats data as JSON
4. Writes to /app/data/metrics_<timestamp>.json
5. Creates symlink: latest_metrics.json
6. InfluxDB Writer reads metrics
7. Writes to InfluxDB time-series database
```

### Alert Flow
```
1. Alert Script runs every 30 seconds
2. Reads latest_metrics.json
3. Compares values to thresholds
4. Checks alert cooldown state
5. Generates alert if needed
6. Writes to alerts.jsonl
7. Updates cooldown state
8. Logs to alerts.log
```

### Web Dashboard Flow
```
1. User opens http://localhost:3000
2. React app loads
3. JavaScript fetches /api/metrics/latest
4. API reads latest_metrics.json
5. Returns JSON to frontend
6. React renders components
7. Updates every 5 seconds
```

### Report Generation Flow
```
1. Processor runs every hour
2. Loads metrics from last 24 hours
3. Calculates statistics
4. Generates HTML report
5. Saves to reports/latest_report.html
6. Creates JSON summary
7. Saves to data/latest_summary.json
```

## File Structure

### Shared Volumes

#### /app/data
```
metrics_<timestamp>.json  - Individual metric snapshots
latest_metrics.json       - Symlink to latest
alerts.jsonl              - Alert history (JSON Lines)
latest_summary.json       - Latest statistics
summary_<timestamp>.json  - Historical summaries
.last_processed_influx    - InfluxDB writer state
last_alerts.state         - Alert cooldown state
```

#### /app/logs
```
monitor.log         - Monitor activity log
monitor_error.log   - Monitor errors
alerts.log          - Alert activity log
```

#### /app/reports
```
latest_report.html       - Latest HTML report (symlink)
report_<timestamp>.html  - Historical HTML reports
```

## Network Architecture

### Docker Network: monitoring
```
Service         IP Range        Ports
-------         --------        -----
monitor         172.x.x.x       -
alerts          172.x.x.x       -
processor       172.x.x.x       -
api             172.x.x.x       8000 (exposed)
web             172.x.x.x       80 → 3000 (exposed)
influxdb        172.x.x.x       8086 (exposed)
grafana         172.x.x.x       3000 → 3001 (exposed)
```

**Note**: All containers communicate via Docker internal network. Only specified ports are exposed to the host.

## Security Model

### Container Isolation
- Each service runs in isolated container
- Limited to specific functions
- Minimal installed packages
- Read-only mounts where possible

### Volume Permissions
- Shared volumes for data exchange
- Monitor has read access to /proc, /sys
- No write access to host filesystem
- Data persists in Docker volumes

### Network Segmentation
- Internal Docker network
- No direct host network access
- Explicit port mappings
- Can be configured as internal-only

### Authentication
- No auth by default (add as needed)
- Grafana: username/password
- InfluxDB: can enable auth
- API: can add token auth

## Scaling Considerations

### Vertical Scaling
- Increase container resource limits
- Add more CPUs/RAM to host
- Increase InfluxDB storage

### Horizontal Scaling
- Deploy monitor on multiple hosts
- Point to central InfluxDB
- Use remote API endpoint
- Load balance web interface

### Data Management
- Configure retention policies
- Archive old reports
- Backup InfluxDB data
- Implement data aggregation

## Performance Characteristics

### Resource Usage (Typical)
```
Container      RAM      CPU      Disk I/O
---------      ---      ---      --------
monitor        50MB     <5%      Low
alerts         30MB     <2%      Low
processor      100MB    <5%      Medium (hourly)
api            100MB    <10%     Medium
web            50MB     <2%      Low
influxdb       200MB    <15%     Medium
grafana        100MB    <5%      Low
---------      ---      ---      --------
TOTAL          ~630MB   <44%     Low-Medium
```

### Data Volume
```
Interval: 5 seconds
Per snapshot: ~1KB
Per hour: ~720KB
Per day: ~17MB
Per week: ~120MB
Per month: ~500MB
```

**With cleanup**: Configurable retention keeps storage manageable

## Monitoring Intervals

### Collection: 5 seconds
- Fast response to changes
- Detailed time-series data
- Good for real-time monitoring

### Alert Check: 30 seconds
- Balance between responsiveness and overhead
- Cooldown prevents alert spam

### Report Generation: 1 hour
- Periodic summaries
- Historical analysis
- Automated documentation

### Data Cleanup: 1 hour
- Remove old metrics (>1000 files)
- Archive old reports (>7 days)
- Maintain disk space

## Extension Points

### Adding New Metrics
1. Update `system_monitor.sh`
2. Add collection function
3. Include in JSON output
4. Update React components
5. Rebuild containers

### Adding New Alerts
1. Update `alert_config.conf`
2. Add threshold variable
3. Update `alert_system.sh`
4. Add check function
5. Restart alerts container

### Custom Visualizations
1. Create new React component
2. Fetch data from API
3. Add to Dashboard.js
4. Rebuild web container

### API Extensions
1. Add endpoint to `api_server.py`
2. Implement data processing
3. Return JSON response
4. Document in README
5. Rebuild API container

---

**This architecture provides a robust, scalable, and maintainable system monitoring solution!**
