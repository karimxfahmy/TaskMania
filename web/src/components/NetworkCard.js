import React from 'react';
import './Dashboard.css';

function NetworkCard({ network }) {
  if (!network || !network.interfaces) return null;

  const formatBytes = (bytes) => {
    const mb = bytes / (1024 * 1024);
    if (mb < 1024) {
      return `${mb.toFixed(2)} MB`;
    }
    const gb = mb / 1024;
    return `${gb.toFixed(2)} GB`;
  };

  const getStatusClass = (status) => {
    return status === 'up' ? 'status-up' : 'status-down';
  };

  const getStatusEmoji = (status) => {
    return status === 'up' ? '🟢' : '🔴';
  };

  return (
    <div className="metric-card">
      <div className="card-header">
        <span className="card-icon">🌐</span>
        <h2 className="card-title">Network</h2>
      </div>
      <div className="card-content">
        {network.interfaces.map((iface, index) => (
          <div key={index} className="metric-item">
            <div className="metric-item-header">
              <span className="device-name">
                {getStatusEmoji(iface.status)} {iface.interface}
              </span>
              <span className={`device-status ${getStatusClass(iface.status)}`}>
                {iface.status}
              </span>
            </div>
            <div className="metric-item-details">
              <div className="detail-item">
                <span className="detail-label">↓ RX Bytes:</span>
                <span className="detail-value">{formatBytes(iface.rx_bytes)}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">↑ TX Bytes:</span>
                <span className="detail-value">{formatBytes(iface.tx_bytes)}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">↓ RX Packets:</span>
                <span className="detail-value">{iface.rx_packets.toLocaleString()}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">↑ TX Packets:</span>
                <span className="detail-value">{iface.tx_packets.toLocaleString()}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">RX Errors:</span>
                <span className="detail-value" style={{ color: iface.rx_errors > 0 ? '#e53e3e' : '#48bb78' }}>
                  {iface.rx_errors}
                </span>
              </div>
              <div className="detail-item">
                <span className="detail-label">TX Errors:</span>
                <span className="detail-value" style={{ color: iface.tx_errors > 0 ? '#e53e3e' : '#48bb78' }}>
                  {iface.tx_errors}
                </span>
              </div>
              <div className="detail-item">
                <span className="detail-label">RX Dropped:</span>
                <span className="detail-value">{iface.rx_dropped}</span>
              </div>
              <div className="detail-item">
                <span className="detail-label">TX Dropped:</span>
                <span className="detail-value">{iface.tx_dropped}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default NetworkCard;
