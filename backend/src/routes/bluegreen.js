const express = require('express');
const router = express.Router();
const bluegreen = require('../services/bluegreenService');

// GET /bluegreen/status — ดูว่า active คือ blue หรือ green
router.get('/status', async (req, res) => {
  try {
    const data = await bluegreen.getStatus();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /bluegreen/switch — สลับ traffic
// body: { targetSlot: "blue" | "green" }
router.post('/switch', async (req, res) => {
  try {
    const { targetSlot } = req.body;
    if (!targetSlot) return res.status(400).json({ error: 'targetSlot required' });
    const result = await bluegreen.switchTraffic(targetSlot);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /bluegreen/rollback — rollback กลับ slot เดิม
router.post('/rollback', async (req, res) => {
  try {
    const result = await bluegreen.rollback();
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;
