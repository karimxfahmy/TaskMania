import React from 'react';
import './Dashboard.css';

function DiskCard({ disk }) {
  if (!disk || !disk.filesystems) return null;

  const formatBytes = (kb) => {
    const gb = kb / (1024 * 1024);
    if (gb < 1) {
      return `${(kb / 1024).toFixed(2)} MB`;
    }
    return `${gb.toFixed(2)} GB`;
  };

  const getUsageClass = (percentage) => {
    if (percentage >= 90) return 'critical';
    if (percentage >= 75) return 'warning';
    return '';
  };

  return (
    <div className="metric-card">
      <div className="card-header">
        <span className="card-icon">💿</span>
        <h2 className="card-title">Disk</h2>
      </div>
      <div className="card-content">
        {disk.filesystems.map((fs, index) => (
          <div key={index} className="metric-item">
            <div className="metric-item-header">
              <span className="device-name">{fs.mount_point}</span>
              <span className={`device-status ${getUsageClass(fs.use_percent) === 'critical' ? 'status-down' : 'status-up'}`}>
                {fs.use_percent}% used
              </span>
            </div>
            <div className="progress-bar-container">
              <div
                className={`progress-bar ${getUsageClass(fs.use_percent)}`}
                style={{ width: `${fs.use_percent}%` }}
              ></div>
            </div>
            <div className="metric-item-details">
              <div className="detail-item">
                <span className="detail-label">Total:</span>
                <span className="detail-value">{formatBytes(fs.total_kb)}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Used:</span>
                <span className="detail-value">{formatBytes(fs.used_kb)}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Available:</span>
                <span className="detail-value">{formatBytes(fs.available_kb)}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Device:</span>
                <span className="detail-value" style={{ fontSize: '0.8rem' }}>
                  {fs.device}
                </span>
              </div>
            </div>
          </div>
        ))}

        {disk.io_stats && disk.io_stats.length > 0 && (
          <div style={{ marginTop: '1rem' }}>
            <h3 style={{ fontSize: '1rem', marginBottom: '0.75rem', color: '#718096' }}>I/O Statistics</h3>
            {disk.io_stats.map((io, index) => (
              <div key={index} className="metric-item">
                <div className="metric-item-header">
                  <span className="device-name">💿 {io.device}</span>
                </div>
                <div className="metric-item-details">
                  <div className="detail-item">
                    <span className="detail-label">Reads:</span>
                    <span className="detail-value">{io.reads.toLocaleString()}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Writes:</span>
                    <span className="detail-value">{io.writes.toLocaleString()}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Sectors Read:</span>
                    <span className="detail-value">{io.sectors_read.toLocaleString()}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Sectors Written:</span>
                    <span className="detail-value">{io.sectors_written.toLocaleString()}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default DiskCard;
