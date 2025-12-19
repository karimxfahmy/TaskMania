import React from 'react';
import './GpuCard.css';

function GpuCard({ gpu }) {
  if (!gpu || !gpu.devices || gpu.devices.length === 0) {
    return (
      <div className="metric-card gpu-card">
        <div className="card-header">
          <h3>🎮 GPU</h3>
        </div>
        <div className="card-body">
          <div className="no-gpu-message">
            <p>No GPU detected</p>
            <small>Install nvidia-smi (NVIDIA) or rocm-smi (AMD) for GPU monitoring</small>
          </div>
        </div>
      </div>
    );
  }

  const getHealthIcon = (health, temp) => {
    if (health === 'virtual') return '💻';
    if (health === 'unknown') return '❓';
    if (temp > 85) return '🔥';
    if (temp > 75) return '🌡️';
    return '✅';
  };

  const getUtilColor = (util) => {
    if (util > 90) return '#e74c3c';
    if (util > 70) return '#f39c12';
    if (util > 50) return '#3498db';
    return '#2ecc71';
  };

  const getTempColor = (temp) => {
    if (temp > 85) return '#e74c3c';
    if (temp > 75) return '#f39c12';
    if (temp > 65) return '#3498db';
    return '#2ecc71';
  };

  return (
    <div className="metric-card gpu-card">
      <div className="card-header">
        <h3>🎮 GPU ({gpu.devices.length})</h3>
      </div>
      <div className="card-body">
        {gpu.devices.map((device, index) => (
          <div key={index} className="gpu-device">
            <div className="gpu-header">
              <div className="gpu-name">
                <strong>{device.name}</strong>
                <span className="gpu-vendor">{device.vendor}</span>
              </div>
              <div className="gpu-health">
                {getHealthIcon(device.health, device.temperature_celsius)}
              </div>
            </div>

            <div className="gpu-metrics">
              {device.utilization_percent > 0 && (
                <div className="gpu-metric">
                  <div className="metric-label">
                    <span>Utilization</span>
                    <span className="metric-value" style={{ color: getUtilColor(device.utilization_percent) }}>
                      {device.utilization_percent}%
                    </span>
                  </div>
                  <div className="progress-bar">
                    <div 
                      className="progress-fill"
                      style={{ 
                        width: `${device.utilization_percent}%`,
                        backgroundColor: getUtilColor(device.utilization_percent)
                      }}
                    ></div>
                  </div>
                </div>
              )}

              {device.temperature_celsius > 0 && (
                <div className="gpu-metric">
                  <div className="metric-label">
                    <span>Temperature</span>
                    <span className="metric-value" style={{ color: getTempColor(device.temperature_celsius) }}>
                      {device.temperature_celsius}°C
                    </span>
                  </div>
                  <div className="progress-bar">
                    <div 
                      className="progress-fill"
                      style={{ 
                        width: `${Math.min((device.temperature_celsius / 100) * 100, 100)}%`,
                        backgroundColor: getTempColor(device.temperature_celsius)
                      }}
                    ></div>
                  </div>
                </div>
              )}

              {device.memory_total_mb > 0 && (
                <div className="gpu-metric">
                  <div className="metric-label">
                    <span>Memory</span>
                    <span className="metric-value">
                      {(device.memory_used_mb / 1024).toFixed(1)} / {(device.memory_total_mb / 1024).toFixed(1)} GB
                    </span>
                  </div>
                  <div className="progress-bar">
                    <div 
                      className="progress-fill"
                      style={{ 
                        width: `${(device.memory_used_mb / device.memory_total_mb) * 100}%`,
                        backgroundColor: '#9b59b6'
                      }}
                    ></div>
                  </div>
                </div>
              )}

              {device.power_draw_watts > 0 && (
                <div className="gpu-metric">
                  <div className="metric-label">
                    <span>Power</span>
                    <span className="metric-value">
                      {device.power_draw_watts}W
                      {device.power_limit_watts > 0 && ` / ${device.power_limit_watts}W`}
                    </span>
                  </div>
                  {device.power_limit_watts > 0 && (
                    <div className="progress-bar">
                      <div 
                        className="progress-fill"
                        style={{ 
                          width: `${(device.power_draw_watts / device.power_limit_watts) * 100}%`,
                          backgroundColor: '#e67e22'
                        }}
                      ></div>
                    </div>
                  )}
                </div>
              )}

              {device.fan_speed_percent > 0 && (
                <div className="gpu-metric">
                  <div className="metric-label">
                    <span>Fan Speed</span>
                    <span className="metric-value">
                      {device.fan_speed_percent}%
                    </span>
                  </div>
                  <div className="progress-bar">
                    <div 
                      className="progress-fill"
                      style={{ 
                        width: `${device.fan_speed_percent}%`,
                        backgroundColor: '#1abc9c'
                      }}
                    ></div>
                  </div>
                </div>
              )}

              {device.note && (
                <div className="gpu-note" style={{
                  background: device.health === 'virtual' 
                    ? 'rgba(155, 89, 182, 0.2)' 
                    : 'rgba(52, 152, 219, 0.2)'
                }}>
                  <small>
                    {device.health === 'virtual' ? '💻' : 'ℹ️'} {device.note}
                  </small>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default GpuCard;

