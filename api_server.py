#!/usr/bin/env python3
"""
API Server for System Monitoring Dashboard
Serves metrics and alerts to the web interface
"""

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import json
import os
from pathlib import Path
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuration
DATA_DIR = os.getenv('DATA_DIR', '/app/data')
REPORTS_DIR = os.getenv('REPORTS_DIR', '/app/reports')


@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })


@app.route('/api/metrics/latest')
def get_latest_metrics():
    """Get the latest system metrics"""
    try:
        metrics_file = Path(DATA_DIR) / 'latest_metrics.json'
        
        if not metrics_file.exists():
            return jsonify({
                'error': 'No metrics available yet',
                'timestamp': datetime.now().isoformat()
            }), 404
        
        with open(metrics_file, 'r') as f:
            metrics = json.load(f)
        
        return jsonify(metrics)
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/api/metrics/history/<int:hours>')
def get_metrics_history(hours):
    """Get metrics history for the last N hours"""
    try:
        data_dir = Path(DATA_DIR)
        cutoff_timestamp = int(datetime.now().timestamp()) - (hours * 3600)
        
        metrics_files = sorted(data_dir.glob('metrics_*.json'))
        history = []
        
        for filepath in metrics_files:
            try:
                timestamp = int(filepath.stem.split('_')[1])
                if timestamp >= cutoff_timestamp:
                    with open(filepath, 'r') as f:
                        metrics = json.load(f)
                        history.append(metrics)
            except (ValueError, IndexError, json.JSONDecodeError):
                continue
        
        return jsonify({
            'hours': hours,
            'count': len(history),
            'metrics': history
        })
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/api/alerts/recent')
def get_recent_alerts():
    """Get recent alerts"""
    try:
        alerts_file = Path(DATA_DIR) / 'alerts.jsonl'
        
        if not alerts_file.exists():
            return jsonify([])
        
        alerts = []
        with open(alerts_file, 'r') as f:
            for line in f:
                try:
                    alert = json.loads(line.strip())
                    alerts.append(alert)
                except json.JSONDecodeError:
                    continue
        
        # Return last 50 alerts, newest first
        return jsonify(alerts[-50:][::-1])
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/api/summary')
def get_summary():
    """Get summary statistics"""
    try:
        summary_file = Path(DATA_DIR) / 'latest_summary.json'
        
        if not summary_file.exists():
            return jsonify({
                'error': 'No summary available yet',
                'timestamp': datetime.now().isoformat()
            }), 404
        
        with open(summary_file, 'r') as f:
            summary = json.load(f)
        
        return jsonify(summary)
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/api/reports/latest')
def get_latest_report():
    """Get the latest HTML report"""
    try:
        report_file = Path(REPORTS_DIR) / 'latest_report.html'
        
        if not report_file.exists():
            return "No report available yet", 404
        
        return send_from_directory(REPORTS_DIR, 'latest_report.html')
    
    except Exception as e:
        return f"Error: {str(e)}", 500


@app.route('/api/reports/list')
def list_reports():
    """List all available reports"""
    try:
        reports_dir = Path(REPORTS_DIR)
        reports = []
        
        for report_file in sorted(reports_dir.glob('report_*.html'), reverse=True):
            try:
                timestamp = int(report_file.stem.split('_')[1])
                reports.append({
                    'filename': report_file.name,
                    'timestamp': timestamp,
                    'datetime': datetime.fromtimestamp(timestamp).isoformat(),
                    'size': report_file.stat().st_size
                })
            except (ValueError, IndexError):
                continue
        
        return jsonify(reports)
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/api/system/info')
def get_system_info():
    """Get system information"""
    try:
        metrics_file = Path(DATA_DIR) / 'latest_metrics.json'
        
        if not metrics_file.exists():
            return jsonify({
                'error': 'No system info available yet'
            }), 404
        
        with open(metrics_file, 'r') as f:
            metrics = json.load(f)
        
        return jsonify(metrics.get('system', {}))
    
    except Exception as e:
        return jsonify({
            'error': str(e)
        }), 500


if __name__ == '__main__':
    # Ensure data directory exists
    Path(DATA_DIR).mkdir(parents=True, exist_ok=True)
    Path(REPORTS_DIR).mkdir(parents=True, exist_ok=True)
    
    # Run the server
    port = int(os.getenv('API_PORT', 8000))
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    print(f"Starting API server on port {port}")
    print(f"Data directory: {DATA_DIR}")
    print(f"Reports directory: {REPORTS_DIR}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
