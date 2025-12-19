import React from 'react';
import './Dashboard.css';
import CPUCard from './CPUCard';
import MemoryCard from './MemoryCard';
import DiskCard from './DiskCard';
import NetworkCard from './NetworkCard';
import GpuCard from './GpuCard';

function Dashboard({ metrics }) {
  if (!metrics) {
    return <div className="dashboard">No metrics available</div>;
  }

  return (
    <div className="dashboard">
      <CPUCard cpu={metrics.cpu} />
      <GpuCard gpu={metrics.gpu} />
      <MemoryCard memory={metrics.memory} />
      <DiskCard disk={metrics.disk} />
      <NetworkCard network={metrics.network} />
    </div>
  );
}

export default Dashboard;
