import React from 'react';
import './Dashboard.css';

function MemoryCard({ memory }) {
  if (!memory) return null;

  const formatBytes = (kb) => {
    const gb = kb / (1024 * 1024);
    return gb.toFixed(2);
  };

  const calculatePercentage = (used, total) => {
    if (total === 0) return 0;
    return ((used / total) * 100).toFixed(1);
  };

  const getUsageClass = (percentage) => {
    if (percentage >= 90) return 'critical';
    if (percentage >= 75) return 'warning';
    return '';
  };

  const memoryUsedPercentage = calculatePercentage(
    memory.used_kb,
    memory.total_kb
  );

  const swapUsedPercentage = calculatePercentage(
    memory.swap_used_kb,
    memory.swap_total_kb
  );

  return (
    <div className="metric-card">
      <div className="card-header">
        <span className="card-icon">💾</span>
        <h2 className="card-title">Memory</h2>
      </div>
      <div className="card-content">
        <div>
          <div className="metric-row">
            <span className="metric-label">RAM Used</span>
            <span className="metric-value">
              {formatBytes(memory.used_kb)} / {formatBytes(memory.total_kb)} GB
            </span>
          </div>
          <div className="progress-bar-container">
            <div
              className={`progress-bar ${getUsageClass(memoryUsedPercentage)}`}
              style={{ width: `${memoryUsedPercentage}%` }}
            ></div>
          </div>
          <div style={{ textAlign: 'right', marginTop: '0.5rem', fontSize: '0.9rem', color: '#718096' }}>
            {memoryUsedPercentage}% used
          </div>
        </div>

        <div className="metric-row">
          <span className="metric-label">Available</span>
          <span className="metric-value">{formatBytes(memory.available_kb)} GB</span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Cached</span>
          <span className="metric-value">{formatBytes(memory.cached_kb)} GB</span>
        </div>

        <div className="metric-row">
          <span className="metric-label">Buffers</span>
          <span className="metric-value">{formatBytes(memory.buffers_kb)} GB</span>
        </div>

        {memory.swap_total_kb > 0 && (
          <div style={{ marginTop: '1rem' }}>
            <div className="metric-row">
              <span className="metric-label">Swap Used</span>
              <span className="metric-value">
                {formatBytes(memory.swap_used_kb)} / {formatBytes(memory.swap_total_kb)} GB
              </span>
            </div>
            <div className="progress-bar-container">
              <div
                className={`progress-bar ${getUsageClass(swapUsedPercentage)}`}
                style={{ width: `${swapUsedPercentage}%` }}
              ></div>
            </div>
            <div style={{ textAlign: 'right', marginTop: '0.5rem', fontSize: '0.9rem', color: '#718096' }}>
              {swapUsedPercentage}% used
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default MemoryCard;
