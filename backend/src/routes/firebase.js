const express = require('express');
const router = express.Router();
const firebase = require('../services/firebaseService');

// GET /firebase/docker-images
router.get('/docker-images', async (req, res) => {
  try {
    const data = await firebase.getDockerImages();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /firebase/k8s-templates
router.get('/k8s-templates', async (req, res) => {
  try {
    const data = await firebase.getK8sTemplates();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /firebase/pipelines
router.get('/pipelines', async (req, res) => {
  try {
    const data = await firebase.getPipelines();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /firebase/tutorials
router.get('/tutorials', async (req, res) => {
  try {
    const data = await firebase.getTutorials();
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;
