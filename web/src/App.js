import React, { useState, useEffect } from 'react';
import './App.css';
import Dashboard from './components/Dashboard';
import AlertPanel from './components/AlertPanel';
import SystemInfo from './components/SystemInfo';

function App() {
  const [metrics, setMetrics] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch latest metrics
  const fetchMetrics = async () => {
    try {
      const response = await fetch('/api/metrics/latest');
      if (!response.ok) throw new Error('Failed to fetch metrics');
      const data = await response.json();
      setMetrics(data);
      setError(null);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching metrics:', err);
    } finally {
      setLoading(false);
    }
  };

  // Fetch alerts
  const fetchAlerts = async () => {
    try {
      const response = await fetch('/api/alerts/recent');
      if (!response.ok) throw new Error('Failed to fetch alerts');
      const data = await response.json();
      setAlerts(data);
    } catch (err) {
      console.error('Error fetching alerts:', err);
    }
  };

  // Auto-refresh every 5 seconds
  useEffect(() => {
    fetchMetrics();
    fetchAlerts();
    
    const interval = setInterval(() => {
      fetchMetrics();
      fetchAlerts();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading system metrics...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <div className="error-message">
          <h2>⚠️ Error</h2>
          <p>{error}</p>
          <button onClick={fetchMetrics}>Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="App">
      <header className="app-header">
        <div className="header-content">
          <h1>
            <span className="logo">📊</span>
            TaskMania System Monitor
          </h1>
          <div className="header-info">
            <span className="status-badge status-active">● Live</span>
            <span className="last-update">
              Last update: {metrics ? new Date(metrics.datetime).toLocaleTimeString() : 'N/A'}
            </span>
          </div>
        </div>
      </header>

      <div className="app-content">
        <div className="main-grid">
          <div className="left-panel">
            <SystemInfo system={metrics?.system} />
            <AlertPanel alerts={alerts} />
          </div>
          
          <div className="right-panel">
            <Dashboard metrics={metrics} />
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
