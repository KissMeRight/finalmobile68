const express = require('express');
const router = express.Router();
const docker = require('../services/dockerService');

// GET /docker/images — รายการ images บนเครื่อง
router.get('/images', async (req, res) => {
  try {
    const images = await docker.listImages();
    res.json({ success: true, data: images });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /docker/containers — รายการ containers ทั้งหมด
router.get('/containers', async (req, res) => {
  try {
    const containers = await docker.listContainers();
    res.json({ success: true, data: containers });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /docker/run — รัน container ใหม่
// body: { image, name, ports }
// ตัวอย่าง: { image: "nginx:latest", name: "my-nginx", ports: { "80/tcp": [{ HostPort: "8080" }] } }
router.post('/run', async (req, res) => {
  try {
    const { image, name, ports } = req.body;
    if (!image) return res.status(400).json({ error: 'image is required' });
    const result = await docker.runContainer({ image, name, ports });
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /docker/stop — หยุด container
// body: { containerId }
router.post('/stop', async (req, res) => {
  try {
    const { containerId } = req.body;
    if (!containerId) return res.status(400).json({ error: 'containerId is required' });
    const result = await docker.stopContainer(containerId);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// DELETE /docker/containers/:id — ลบ container
router.delete('/containers/:id', async (req, res) => {
  try {
    const result = await docker.removeContainer(req.params.id);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /docker/containers/:id/logs — ดู logs
router.get('/containers/:id/logs', async (req, res) => {
  try {
    const logs = await docker.getContainerLogs(req.params.id);
    res.json({ success: true, data: logs });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;
