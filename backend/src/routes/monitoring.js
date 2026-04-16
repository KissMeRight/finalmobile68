const express = require('express');
const router = express.Router();
const prometheus = require('../services/prometheusService');

// GET /monitoring/cluster — overview ของทั้ง cluster
router.get('/cluster', async (req, res) => {
  try {
    const data = await prometheus.getClusterOverview();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /monitoring/pods — resource usage แยกตาม pod
router.get('/pods', async (req, res) => {
  try {
    const data = await prometheus.getPodMetrics();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;
