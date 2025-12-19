import React from 'react';
import './SystemInfo.css';

function SystemInfo({ system }) {
  if (!system) return null;

  const formatUptime = (seconds) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) {
      return `${days}d ${hours}h ${minutes}m`;
    } else if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else {
      return `${minutes}m`;
    }
  };

  return (
    <div className="system-info-card">
      <div className="card-header">
        <span className="card-icon">⚙️</span>
        <h2 className="card-title">System Info</h2>
      </div>
      <div className="system-info-content">
        <div className="info-item">
          <span className="info-icon">🖥️</span>
          <div className="info-details">
            <div className="info-label">Hostname</div>
            <div className="info-value">{system.hostname}</div>
          </div>
        </div>

        <div className="info-item">
          <span className="info-icon">🐧</span>
          <div className="info-details">
            <div className="info-label">Operating System</div>
            <div className="info-value">{system.os_name}</div>
            {system.os_version && (
              <div className="info-subvalue">{system.os_version}</div>
            )}
          </div>
        </div>

        <div className="info-item">
          <span className="info-icon">🔧</span>
          <div className="info-details">
            <div className="info-label">Kernel</div>
            <div className="info-value">{system.kernel}</div>
          </div>
        </div>

        <div className="info-item">
          <span className="info-icon">💻</span>
          <div className="info-details">
            <div className="info-label">Architecture</div>
            <div className="info-value">{system.architecture}</div>
          </div>
        </div>

        <div className="info-item">
          <span className="info-icon">⏱️</span>
          <div className="info-details">
            <div className="info-label">Uptime</div>
            <div className="info-value">{formatUptime(system.uptime_seconds)}</div>
          </div>
        </div>

        <div className="info-item">
          <span className="info-icon">📊</span>
          <div className="info-details">
            <div className="info-label">Processes</div>
            <div className="info-value">{system.process_count}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SystemInfo;
