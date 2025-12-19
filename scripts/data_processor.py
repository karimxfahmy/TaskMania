#!/usr/bin/env python3
"""
Data Processor for System Monitoring
Aggregates and analyzes metrics data
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any
import statistics

# Configuration
DATA_DIR = os.getenv('DATA_DIR', '/app/data')
LOG_DIR = os.getenv('LOG_DIR', '/app/logs')
REPORTS_DIR = os.getenv('REPORTS_DIR', '/app/reports')


class MetricsProcessor:
    """Process and analyze system metrics"""
    
    def __init__(self):
        self.data_dir = Path(DATA_DIR)
        self.log_dir = Path(LOG_DIR)
        self.reports_dir = Path(REPORTS_DIR)
        
        # Ensure directories exist
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.reports_dir.mkdir(parents=True, exist_ok=True)
    
    def load_metrics_file(self, filepath: Path) -> Dict[str, Any]:
        """Load a single metrics file"""
        try:
            with open(filepath, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading {filepath}: {e}", file=sys.stderr)
            return {}
    
    def load_recent_metrics(self, hours: int = 1) -> List[Dict[str, Any]]:
        """Load metrics from the last N hours"""
        cutoff_time = datetime.now() - timedelta(hours=hours)
        cutoff_timestamp = int(cutoff_time.timestamp())
        
        metrics_files = sorted(self.data_dir.glob('metrics_*.json'))
        recent_metrics = []
        
        for filepath in metrics_files:
            try:
                # Extract timestamp from filename
                timestamp = int(filepath.stem.split('_')[1])
                if timestamp >= cutoff_timestamp:
                    metrics = self.load_metrics_file(filepath)
                    if metrics:
                        recent_metrics.append(metrics)
            except (ValueError, IndexError):
                continue
        
        return recent_metrics
    
    def calculate_cpu_stats(self, metrics_list: List[Dict[str, Any]]) -> Dict[str, float]:
        """Calculate CPU statistics"""
        loads_1min = []
        loads_5min = []
        loads_15min = []
        temps = []
        
        for metrics in metrics_list:
            cpu = metrics.get('cpu', {})
            if 'load_1min' in cpu:
                loads_1min.append(float(cpu['load_1min']))
            if 'load_5min' in cpu:
                loads_5min.append(float(cpu['load_5min']))
            if 'load_15min' in cpu:
                loads_15min.append(float(cpu['load_15min']))
            
            temp = cpu.get('temperature_celsius')
            if temp and temp != 'null':
                temps.append(float(temp))
        
        stats = {}
        
        if loads_1min:
            stats['load_1min_avg'] = statistics.mean(loads_1min)
            stats['load_1min_max'] = max(loads_1min)
            stats['load_1min_min'] = min(loads_1min)
        
        if loads_5min:
            stats['load_5min_avg'] = statistics.mean(loads_5min)
        
        if loads_15min:
            stats['load_15min_avg'] = statistics.mean(loads_15min)
        
        if temps:
            stats['temp_avg'] = statistics.mean(temps)
            stats['temp_max'] = max(temps)
            stats['temp_min'] = min(temps)
        
        return stats
    
    def calculate_memory_stats(self, metrics_list: List[Dict[str, Any]]) -> Dict[str, float]:
        """Calculate memory statistics"""
        mem_used_percent = []
        swap_used_percent = []
        
        for metrics in metrics_list:
            memory = metrics.get('memory', {})
            
            total_kb = memory.get('total_kb', 0)
            available_kb = memory.get('available_kb', 0)
            if total_kb > 0:
                used_kb = total_kb - available_kb
                used_percent = (used_kb / total_kb) * 100
                mem_used_percent.append(used_percent)
            
            swap_total = memory.get('swap_total_kb', 0)
            swap_used = memory.get('swap_used_kb', 0)
            if swap_total > 0:
                swap_percent = (swap_used / swap_total) * 100
                swap_used_percent.append(swap_percent)
        
        stats = {}
        
        if mem_used_percent:
            stats['memory_used_avg'] = statistics.mean(mem_used_percent)
            stats['memory_used_max'] = max(mem_used_percent)
            stats['memory_used_min'] = min(mem_used_percent)
        
        if swap_used_percent:
            stats['swap_used_avg'] = statistics.mean(swap_used_percent)
            stats['swap_used_max'] = max(swap_used_percent)
        
        return stats
    
    def calculate_disk_stats(self, metrics_list: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate disk statistics"""
        disk_usage = {}
        
        for metrics in metrics_list:
            disk = metrics.get('disk', {})
            filesystems = disk.get('filesystems', [])
            
            for fs in filesystems:
                mount_point = fs.get('mount_point', 'unknown')
                use_percent = fs.get('use_percent', 0)
                
                if mount_point not in disk_usage:
                    disk_usage[mount_point] = []
                disk_usage[mount_point].append(use_percent)
        
        stats = {}
        for mount_point, percentages in disk_usage.items():
            if percentages:
                stats[mount_point] = {
                    'avg': statistics.mean(percentages),
                    'max': max(percentages),
                    'min': min(percentages)
                }
        
        return stats
    
    def calculate_network_stats(self, metrics_list: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate network statistics"""
        if len(metrics_list) < 2:
            return {}
        
        # Calculate rates between first and last metrics
        first_metrics = metrics_list[0]
        last_metrics = metrics_list[-1]
        
        time_diff = last_metrics.get('timestamp', 0) - first_metrics.get('timestamp', 0)
        if time_diff <= 0:
            return {}
        
        network_stats = {}
        
        first_interfaces = {iface['interface']: iface 
                           for iface in first_metrics.get('network', {}).get('interfaces', [])}
        last_interfaces = {iface['interface']: iface 
                          for iface in last_metrics.get('network', {}).get('interfaces', [])}
        
        for iface_name in first_interfaces.keys():
            if iface_name in last_interfaces:
                first = first_interfaces[iface_name]
                last = last_interfaces[iface_name]
                
                rx_bytes_diff = last['rx_bytes'] - first['rx_bytes']
                tx_bytes_diff = last['tx_bytes'] - first['tx_bytes']
                
                rx_rate_mbps = (rx_bytes_diff * 8) / (time_diff * 1_000_000)
                tx_rate_mbps = (tx_bytes_diff * 8) / (time_diff * 1_000_000)
                
                network_stats[iface_name] = {
                    'rx_rate_mbps': round(rx_rate_mbps, 2),
                    'tx_rate_mbps': round(tx_rate_mbps, 2),
                    'rx_errors': last['rx_errors'],
                    'tx_errors': last['tx_errors'],
                    'status': last['status']
                }
        
        return network_stats
    
    def generate_summary(self, hours: int = 1) -> Dict[str, Any]:
        """Generate summary statistics"""
        metrics_list = self.load_recent_metrics(hours)
        
        if not metrics_list:
            return {
                'error': 'No metrics available',
                'timestamp': datetime.now().isoformat()
            }
        
        summary = {
            'timestamp': datetime.now().isoformat(),
            'period_hours': hours,
            'samples_count': len(metrics_list),
            'cpu': self.calculate_cpu_stats(metrics_list),
            'memory': self.calculate_memory_stats(metrics_list),
            'disk': self.calculate_disk_stats(metrics_list),
            'network': self.calculate_network_stats(metrics_list)
        }
        
        # Add latest system info
        if metrics_list:
            latest = metrics_list[-1]
            summary['system'] = latest.get('system', {})
        
        return summary
    
    def save_summary(self, summary: Dict[str, Any], filename: str = None):
        """Save summary to file"""
        if filename is None:
            filename = f"summary_{int(datetime.now().timestamp())}.json"
        
        filepath = self.data_dir / filename
        with open(filepath, 'w') as f:
            json.dump(summary, f, indent=2)
        
        # Also save as latest
        latest_path = self.data_dir / 'latest_summary.json'
        with open(latest_path, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"Summary saved to {filepath}")
        return filepath
    
    def generate_html_report(self, hours: int = 24) -> str:
        """Generate HTML report"""
        summary = self.generate_summary(hours)
        
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Monitoring Report</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }}
        .header h1 {{
            margin: 0;
            font-size: 2em;
        }}
        .header .subtitle {{
            opacity: 0.9;
            margin-top: 10px;
        }}
        .section {{
            background: white;
            padding: 25px;
            margin-bottom: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        .section h2 {{
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }}
        .metric {{
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }}
        .metric:last-child {{
            border-bottom: none;
        }}
        .metric-name {{
            color: #666;
        }}
        .metric-value {{
            font-weight: bold;
            color: #333;
        }}
        .status-good {{ color: #27ae60; }}
        .status-warning {{ color: #f39c12; }}
        .status-critical {{ color: #e74c3c; }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>System Monitoring Report</h1>
        <div class="subtitle">
            Generated: {summary.get('timestamp', 'N/A')}<br>
            Period: Last {hours} hour(s) | Samples: {summary.get('samples_count', 0)}
        </div>
    </div>
"""
        
        # System Info
        system = summary.get('system', {})
        if system:
            html += f"""
    <div class="section">
        <h2>System Information</h2>
        <div class="metric">
            <span class="metric-name">Hostname:</span>
            <span class="metric-value">{system.get('hostname', 'N/A')}</span>
        </div>
        <div class="metric">
            <span class="metric-name">OS:</span>
            <span class="metric-value">{system.get('os_name', 'N/A')} {system.get('os_version', '')}</span>
        </div>
        <div class="metric">
            <span class="metric-name">Kernel:</span>
            <span class="metric-value">{system.get('kernel', 'N/A')}</span>
        </div>
        <div class="metric">
            <span class="metric-name">Uptime:</span>
            <span class="metric-value">{float(system.get('uptime_seconds', 0)) / 3600:.1f} hours</span>
        </div>
    </div>
"""
        
        # CPU Stats
        cpu = summary.get('cpu', {})
        if cpu:
            html += f"""
    <div class="section">
        <h2>CPU Statistics</h2>
        <div class="grid">
"""
            if 'load_1min_avg' in cpu:
                html += f"""
            <div class="metric">
                <span class="metric-name">Average Load (1min):</span>
                <span class="metric-value">{cpu['load_1min_avg']:.2f}</span>
            </div>
            <div class="metric">
                <span class="metric-name">Peak Load (1min):</span>
                <span class="metric-value">{cpu['load_1min_max']:.2f}</span>
            </div>
"""
            if 'temp_avg' in cpu:
                html += f"""
            <div class="metric">
                <span class="metric-name">Average Temperature:</span>
                <span class="metric-value">{cpu['temp_avg']:.1f}°C</span>
            </div>
            <div class="metric">
                <span class="metric-name">Peak Temperature:</span>
                <span class="metric-value">{cpu['temp_max']:.1f}°C</span>
            </div>
"""
            html += """
        </div>
    </div>
"""
        
        # Memory Stats
        memory = summary.get('memory', {})
        if memory:
            html += f"""
    <div class="section">
        <h2>Memory Statistics</h2>
        <div class="grid">
"""
            if 'memory_used_avg' in memory:
                html += f"""
            <div class="metric">
                <span class="metric-name">Average Usage:</span>
                <span class="metric-value">{memory['memory_used_avg']:.1f}%</span>
            </div>
            <div class="metric">
                <span class="metric-name">Peak Usage:</span>
                <span class="metric-value">{memory['memory_used_max']:.1f}%</span>
            </div>
"""
            if 'swap_used_avg' in memory:
                html += f"""
            <div class="metric">
                <span class="metric-name">Average Swap:</span>
                <span class="metric-value">{memory['swap_used_avg']:.1f}%</span>
            </div>
"""
            html += """
        </div>
    </div>
"""
        
        # Disk Stats
        disk = summary.get('disk', {})
        if disk:
            html += """
    <div class="section">
        <h2>Disk Usage</h2>
"""
            for mount_point, stats in disk.items():
                status_class = 'status-good'
                if stats['max'] > 90:
                    status_class = 'status-critical'
                elif stats['max'] > 75:
                    status_class = 'status-warning'
                
                html += f"""
        <div class="metric">
            <span class="metric-name">{mount_point}:</span>
            <span class="metric-value {status_class}">{stats['avg']:.1f}% avg, {stats['max']:.1f}% peak</span>
        </div>
"""
            html += """
    </div>
"""
        
        # Network Stats
        network = summary.get('network', {})
        if network:
            html += """
    <div class="section">
        <h2>Network Statistics</h2>
"""
            for iface, stats in network.items():
                html += f"""
        <h3>{iface}</h3>
        <div class="metric">
            <span class="metric-name">RX Rate:</span>
            <span class="metric-value">{stats['rx_rate_mbps']:.2f} Mbps</span>
        </div>
        <div class="metric">
            <span class="metric-name">TX Rate:</span>
            <span class="metric-value">{stats['tx_rate_mbps']:.2f} Mbps</span>
        </div>
        <div class="metric">
            <span class="metric-name">RX Errors:</span>
            <span class="metric-value">{stats['rx_errors']}</span>
        </div>
        <div class="metric">
            <span class="metric-name">TX Errors:</span>
            <span class="metric-value">{stats['tx_errors']}</span>
        </div>
"""
            html += """
    </div>
"""
        
        html += """
</body>
</html>
"""
        
        return html
    
    def save_html_report(self, hours: int = 24):
        """Save HTML report"""
        html = self.generate_html_report(hours)
        timestamp = int(datetime.now().timestamp())
        filename = f"report_{timestamp}.html"
        filepath = self.reports_dir / filename
        
        with open(filepath, 'w') as f:
            f.write(html)
        
        # Also save as latest
        latest_path = self.reports_dir / 'latest_report.html'
        with open(latest_path, 'w') as f:
            f.write(html)
        
        print(f"HTML report saved to {filepath}")
        return filepath
    
    def cleanup_old_files(self, days: int = 7):
        """Clean up old metrics and reports"""
        cutoff_time = datetime.now() - timedelta(days=days)
        cutoff_timestamp = int(cutoff_time.timestamp())
        
        deleted_count = 0
        
        # Clean metrics
        for filepath in self.data_dir.glob('metrics_*.json'):
            try:
                timestamp = int(filepath.stem.split('_')[1])
                if timestamp < cutoff_timestamp:
                    filepath.unlink()
                    deleted_count += 1
            except (ValueError, IndexError):
                continue
        
        # Clean reports
        for filepath in self.reports_dir.glob('report_*.html'):
            try:
                timestamp = int(filepath.stem.split('_')[1])
                if timestamp < cutoff_timestamp:
                    filepath.unlink()
                    deleted_count += 1
            except (ValueError, IndexError):
                continue
        
        print(f"Cleaned up {deleted_count} old files")
        return deleted_count


def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Process system monitoring data')
    parser.add_argument('action', choices=['summary', 'report', 'cleanup'],
                       help='Action to perform')
    parser.add_argument('--hours', type=int, default=1,
                       help='Number of hours to analyze (default: 1)')
    parser.add_argument('--days', type=int, default=7,
                       help='Number of days to keep (for cleanup, default: 7)')
    
    args = parser.parse_args()
    
    processor = MetricsProcessor()
    
    if args.action == 'summary':
        summary = processor.generate_summary(args.hours)
        processor.save_summary(summary)
        print(json.dumps(summary, indent=2))
    
    elif args.action == 'report':
        processor.save_html_report(args.hours)
    
    elif args.action == 'cleanup':
        processor.cleanup_old_files(args.days)


if __name__ == '__main__':
    main()
