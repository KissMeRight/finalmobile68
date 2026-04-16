const axios = require('axios');

const PROMETHEUS_URL = process.env.PROMETHEUS_URL || 'http://localhost:9090';

// Query Prometheus ด้วย PromQL
const query = async (promql) => {
  const res = await axios.get(`${PROMETHEUS_URL}/api/v1/query`, {
    params: { query: promql },
  });
  if (res.data.status !== 'success') throw new Error('Prometheus query failed');
  return res.data.data.result;
};

// CPU usage รวมทั้ง cluster (%)
const getClusterCPU = async () => {
  const results = await query(
    '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
  );
  const value = results[0]?.value[1];
  return { cpu: value ? parseFloat(value).toFixed(2) : null, unit: '%' };
};

// Memory usage รวมทั้ง cluster (%)
const getClusterMemory = async () => {
  const results = await query(
    '(1 - (sum(node_memory_MemAvailable_bytes) / sum(node_memory_MemTotal_bytes))) * 100'
  );
  const value = results[0]?.value[1];
  return { memory: value ? parseFloat(value).toFixed(2) : null, unit: '%' };
};

// จำนวน pods ที่ running
const getRunningPods = async () => {
  const results = await query(
    'count(kube_pod_status_phase{phase="Running"})'
  );
  const value = results[0]?.value[1];
  return { runningPods: value ? parseInt(value) : 0 };
};

// Cluster overview รวมทุก metric
const getClusterOverview = async () => {
  try {
    const [cpu, memory, pods] = await Promise.all([
      getClusterCPU(),
      getClusterMemory(),
      getRunningPods(),
    ]);
    return { ...cpu, ...memory, ...pods, timestamp: new Date().toISOString() };
  } catch (e) {
    // ถ้า Prometheus ยังไม่ได้ติดตั้ง → คืน mock data สำหรับ demo
    console.warn('Prometheus not available, returning mock data');
    return {
      cpu: (Math.random() * 30 + 10).toFixed(2),
      memory: (Math.random() * 40 + 20).toFixed(2),
      runningPods: Math.floor(Math.random() * 5 + 2),
      unit: '%',
      mock: true,
      timestamp: new Date().toISOString(),
    };
  }
};

// Pod resource usage แยกตาม pod
const getPodMetrics = async () => {
  try {
    const results = await query(
      'sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod)'
    );
    return results.map(r => ({
      pod: r.metric.pod,
      cpu: parseFloat(r.value[1]).toFixed(4),
    }));
  } catch (e) {
    return [];
  }
};

module.exports = { getClusterOverview, getClusterCPU, getClusterMemory, getRunningPods, getPodMetrics };
