import React from 'react';
import './Dashboard.css';

function CPUCard({ cpu }) {
  if (!cpu) return null;

  const calculateCPUUsage = () => {
    if (cpu.used_ticks && cpu.total_ticks && cpu.total_ticks > 0) {
      return ((cpu.used_ticks / cpu.total_ticks) * 100).toFixed(1);
    }
    return 0;
  };

  const cpuUsage = calculateCPUUsage();
  const getUsageClass = (usage) => {
    if (usage >= 90) return 'critical';
    if (usage >= 70) return 'warning';
    return '';
  };

  const getTempClass = (temp) => {
    if (!temp || temp === 'null') return 'temp-normal';
    const t = parseFloat(temp);
    if (t >= 80) return 'temp-hot';
    if (t >= 65) return 'temp-warm';
    return 'temp-normal';
  };

  const getTempEmoji = (temp) => {
    if (!temp || temp === 'null') return '🌡️';
    const t = parseFloat(temp);
    if (t >= 80) return '🔥';
    if (t >= 65) return '🌡️';
    return '❄️';
  };

  return (
    <div className="metric-card">
      <div className="card-header">
        <span className="card-icon">🖥️</span>
        <h2 className="card-title">CPU</h2>
      </div>
      <div className="card-content">
        <div className="metric-row">
          <span className="metric-label">Model</span>
          <span className="metric-value" style={{ fontSize: '0.85rem' }}>
            {cpu.model || 'Unknown'}
          </span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Cores</span>
          <span className="metric-value">{cpu.core_count || 0}</span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Usage</span>
          <span className="metric-value">{cpuUsage}%</span>
        </div>
        <div className="progress-bar-container">
          <div
            className={`progress-bar ${getUsageClass(cpuUsage)}`}
            style={{ width: `${cpuUsage}%` }}
          ></div>
        </div>

        <div className="metric-row">
          <span className="metric-label">Load Average (1min)</span>
          <span className="metric-value">{cpu.load_1min?.toFixed(2) || 'N/A'}</span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Load Average (5min)</span>
          <span className="metric-value">{cpu.load_5min?.toFixed(2) || 'N/A'}</span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Load Average (15min)</span>
          <span className="metric-value">{cpu.load_15min?.toFixed(2) || 'N/A'}</span>
        </div>

        {cpu.temperature_celsius && cpu.temperature_celsius !== 'null' && (
          <>
            <div className="metric-row">
              <span className="metric-label">Temperature</span>
              <span className={`temp-indicator ${getTempClass(cpu.temperature_celsius)}`}>
                {getTempEmoji(cpu.temperature_celsius)} {parseFloat(cpu.temperature_celsius).toFixed(1)}°C
              </span>
            </div>
            <div className="progress-bar-container">
              <div
                className={`progress-bar ${getTempClass(cpu.temperature_celsius) === 'temp-hot' ? 'critical' : getTempClass(cpu.temperature_celsius) === 'temp-warm' ? 'warning' : ''}`}
                style={{ 
                  width: `${Math.min(((parseFloat(cpu.temperature_celsius) - 35) / 50) * 100, 100)}%`
                }}
              ></div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default CPUCard;
