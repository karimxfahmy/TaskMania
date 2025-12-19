#!/usr/bin/env python3
"""
InfluxDB Writer
Writes metrics to InfluxDB for time-series storage
"""

import json
import os
import time
from pathlib import Path
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import sys


class InfluxDBWriter:
    """Write metrics to InfluxDB"""
    
    def __init__(self):
        self.influxdb_url = os.getenv('INFLUXDB_URL', 'http://influxdb:8086')
        self.database = os.getenv('INFLUXDB_DB', 'system_monitoring')
        self.data_dir = Path(os.getenv('DATA_DIR', '/app/data'))
        self.last_processed_file = self.data_dir / '.last_processed_influx'
        
    def create_database(self):
        """Create the database if it doesn't exist"""
        try:
            url = f"{self.influxdb_url}/query"
            data = f"q=CREATE DATABASE {self.database}".encode('utf-8')
            req = Request(url, data=data, method='POST')
            req.add_header('Content-Type', 'application/x-www-form-urlencoded')
            
            with urlopen(req, timeout=10) as response:
                return response.status == 200
        except Exception as e:
            print(f"Error creating database: {e}", file=sys.stderr)
            return False
    
    def write_metric(self, measurement, tags, fields, timestamp):
        """Write a single metric to InfluxDB"""
        try:
            # Build line protocol
            tag_str = ','.join([f"{k}={v}" for k, v in tags.items()])
            field_str = ','.join([f"{k}={v}" for k, v in fields.items()])
            
            line = f"{measurement},{tag_str} {field_str} {timestamp}"
            
            # Write to InfluxDB
            url = f"{self.influxdb_url}/write?db={self.database}"
            data = line.encode('utf-8')
            req = Request(url, data=data, method='POST')
            
            with urlopen(req, timeout=10) as response:
                return response.status == 204
        except Exception as e:
            print(f"Error writing metric: {e}", file=sys.stderr)
            return False
    
    def process_metrics_file(self, filepath):
        """Process a metrics file and write to InfluxDB"""
        try:
            with open(filepath, 'r') as f:
                metrics = json.load(f)
            
            timestamp = metrics.get('timestamp', int(time.time()))
            timestamp_ns = timestamp * 1_000_000_000  # Convert to nanoseconds
            
            hostname = metrics.get('system', {}).get('hostname', 'unknown')
            
            # Write CPU metrics
            cpu = metrics.get('cpu', {})
            if cpu:
                self.write_metric(
                    'cpu',
                    {'host': hostname},
                    {
                        'load_1min': cpu.get('load_1min', 0),
                        'load_5min': cpu.get('load_5min', 0),
                        'load_15min': cpu.get('load_15min', 0),
                        'core_count': cpu.get('core_count', 0)
                    },
                    timestamp_ns
                )
                
                if cpu.get('temperature_celsius') and cpu.get('temperature_celsius') != 'null':
                    self.write_metric(
                        'cpu_temperature',
                        {'host': hostname},
                        {'celsius': float(cpu['temperature_celsius'])},
                        timestamp_ns
                    )
            
            # Write memory metrics
            memory = metrics.get('memory', {})
            if memory:
                total_kb = memory.get('total_kb', 0)
                available_kb = memory.get('available_kb', 0)
                
                if total_kb > 0:
                    used_kb = total_kb - available_kb
                    used_percent = (used_kb / total_kb) * 100
                    
                    self.write_metric(
                        'memory',
                        {'host': hostname},
                        {
                            'total_kb': total_kb,
                            'used_kb': used_kb,
                            'available_kb': available_kb,
                            'used_percent': used_percent
                        },
                        timestamp_ns
                    )
                
                # Swap metrics
                swap_total = memory.get('swap_total_kb', 0)
                swap_used = memory.get('swap_used_kb', 0)
                if swap_total > 0:
                    swap_percent = (swap_used / swap_total) * 100
                    self.write_metric(
                        'swap',
                        {'host': hostname},
                        {
                            'total_kb': swap_total,
                            'used_kb': swap_used,
                            'used_percent': swap_percent
                        },
                        timestamp_ns
                    )
            
            # Write disk metrics
            disk = metrics.get('disk', {})
            if disk:
                for fs in disk.get('filesystems', []):
                    mount_point = fs.get('mount_point', 'unknown')
                    self.write_metric(
                        'disk',
                        {
                            'host': hostname,
                            'mount_point': mount_point,
                            'device': fs.get('device', 'unknown')
                        },
                        {
                            'total_kb': fs.get('total_kb', 0),
                            'used_kb': fs.get('used_kb', 0),
                            'available_kb': fs.get('available_kb', 0),
                            'used_percent': fs.get('use_percent', 0)
                        },
                        timestamp_ns
                    )
            
            # Write network metrics
            network = metrics.get('network', {})
            if network:
                for iface in network.get('interfaces', []):
                    interface_name = iface.get('interface', 'unknown')
                    self.write_metric(
                        'network',
                        {
                            'host': hostname,
                            'interface': interface_name
                        },
                        {
                            'rx_bytes': iface.get('rx_bytes', 0),
                            'tx_bytes': iface.get('tx_bytes', 0),
                            'rx_packets': iface.get('rx_packets', 0),
                            'tx_packets': iface.get('tx_packets', 0),
                            'rx_errors': iface.get('rx_errors', 0),
                            'tx_errors': iface.get('tx_errors', 0)
                        },
                        timestamp_ns
                    )
            
            return True
        except Exception as e:
            print(f"Error processing metrics file {filepath}: {e}", file=sys.stderr)
            return False
    
    def get_last_processed_timestamp(self):
        """Get the timestamp of the last processed file"""
        if self.last_processed_file.exists():
            try:
                with open(self.last_processed_file, 'r') as f:
                    return int(f.read().strip())
            except:
                pass
        return 0
    
    def save_last_processed_timestamp(self, timestamp):
        """Save the timestamp of the last processed file"""
        try:
            with open(self.last_processed_file, 'w') as f:
                f.write(str(timestamp))
        except Exception as e:
            print(f"Error saving last processed timestamp: {e}", file=sys.stderr)
    
    def run(self):
        """Main loop to process metrics files"""
        print("Starting InfluxDB writer...")
        
        # Create database
        self.create_database()
        
        last_processed = self.get_last_processed_timestamp()
        
        while True:
            try:
                # Find new metrics files
                metrics_files = sorted(self.data_dir.glob('metrics_*.json'))
                
                for filepath in metrics_files:
                    try:
                        timestamp = int(filepath.stem.split('_')[1])
                        if timestamp > last_processed:
                            if self.process_metrics_file(filepath):
                                print(f"Processed: {filepath.name}")
                                last_processed = timestamp
                                self.save_last_processed_timestamp(timestamp)
                    except (ValueError, IndexError):
                        continue
                
            except Exception as e:
                print(f"Error in main loop: {e}", file=sys.stderr)
            
            # Wait before checking for new files
            time.sleep(5)


def main():
    writer = InfluxDBWriter()
    writer.run()


if __name__ == '__main__':
    main()
