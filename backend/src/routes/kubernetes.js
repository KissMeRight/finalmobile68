const express = require('express');
const router = express.Router();
const k8s = require('../services/k8sService');

// GET /k8s/pods
router.get('/pods', async (req, res) => {
  try {
    const pods = await k8s.getPods();
    res.json({ success: true, data: pods });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /k8s/nodes
router.get('/nodes', async (req, res) => {
  try {
    const nodes = await k8s.getNodes();
    res.json({ success: true, data: nodes });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /k8s/deployments
router.get('/deployments', async (req, res) => {
  try {
    const deployments = await k8s.getDeployments();
    res.json({ success: true, data: deployments });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /k8s/services
router.get('/services', async (req, res) => {
  try {
    const services = await k8s.getServices();
    res.json({ success: true, data: services });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /k8s/deploy
router.post('/deploy', async (req, res) => {
  try {
    const { name, image, replicas = 1, port = 80, slot = 'blue' } = req.body;
    if (!name || !image) return res.status(400).json({ error: 'name and image are required' });
    const manifest = {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: { name, labels: { app: name, slot } },
      spec: {
        replicas: parseInt(replicas),
        selector: { matchLabels: { app: name, slot } },
        template: {
          metadata: { labels: { app: name, slot } },
          spec: {
            containers: [{ name, image, ports: [{ containerPort: parseInt(port) }] }],
          },
        },
      },
    };
    const result = await k8s.deployApp(manifest);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /k8s/scale
router.post('/scale', async (req, res) => {
  try {
    const { name, replicas } = req.body;
    if (!name || replicas === undefined) return res.status(400).json({ error: 'name and replicas required' });
    const result = await k8s.scaleDeployment(name, replicas);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// DELETE /k8s/pods/:name — ลบ pod
router.delete('/pods/:name', async (req, res) => {
  try {
    const result = await k8s.deletePod(req.params.name);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// DELETE /k8s/deployments/:name — ลบ deployment (pods ถูกลบตามอัตโนมัติ)
router.delete('/deployments/:name', async (req, res) => {
  try {
    const result = await k8s.deleteDeployment(req.params.name);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// DELETE /k8s/services/:name — ลบ service
router.delete('/services/:name', async (req, res) => {
  try {
    const result = await k8s.deleteService(req.params.name);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// POST /k8s/deployments/:name/restart — restart deployment (rolling restart)
router.post('/deployments/:name/restart', async (req, res) => {
  try {
    const result = await k8s.restartDeployment(req.params.name);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;