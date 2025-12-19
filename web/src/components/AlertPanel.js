import React, { useState } from 'react';
import './AlertPanel.css';

function AlertPanel({ alerts }) {
  const [expanded, setExpanded] = useState(false);

  if (!alerts || alerts.length === 0) {
    return (
      <div className="alert-panel">
        <div className="card-header">
          <span className="card-icon">🔔</span>
          <h2 className="card-title">Alerts</h2>
        </div>
        <div className="no-alerts">
          <span className="no-alerts-icon">✅</span>
          <p>All systems operating normally</p>
        </div>
      </div>
    );
  }

  const displayedAlerts = expanded ? alerts : alerts.slice(0, 5);
  const hasMore = alerts.length > 5;

  const getSeverityClass = (severity) => {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return 'alert-critical';
      case 'WARNING':
        return 'alert-warning';
      case 'INFO':
        return 'alert-info';
      default:
        return 'alert-info';
    }
  };

  const getSeverityIcon = (severity) => {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return '🚨';
      case 'WARNING':
        return '⚠️';
      case 'INFO':
        return 'ℹ️';
      default:
        return '📌';
    }
  };

  const formatTime = (timestamp) => {
    try {
      const date = new Date(timestamp);
      return date.toLocaleTimeString();
    } catch {
      return timestamp;
    }
  };

  return (
    <div className="alert-panel">
      <div className="card-header">
        <span className="card-icon">🔔</span>
        <h2 className="card-title">
          Alerts
          <span className="alert-count">{alerts.length}</span>
        </h2>
      </div>
      <div className="alerts-list">
        {displayedAlerts.map((alert, index) => (
          <div key={index} className={`alert-item ${getSeverityClass(alert.severity)}`}>
            <div className="alert-header">
              <span className="alert-icon">{getSeverityIcon(alert.severity)}</span>
              <div className="alert-info">
                <div className="alert-title">{alert.title}</div>
                <div className="alert-time">{formatTime(alert.timestamp)}</div>
              </div>
              <span className={`alert-badge ${getSeverityClass(alert.severity)}`}>
                {alert.severity}
              </span>
            </div>
            <div className="alert-message">{alert.message}</div>
          </div>
        ))}
      </div>
      {hasMore && (
        <button
          className="expand-button"
          onClick={() => setExpanded(!expanded)}
        >
          {expanded ? '▲ Show Less' : `▼ Show ${alerts.length - 5} More`}
        </button>
      )}
    </div>
  );
}

export default AlertPanel;
