const express = require('express');
const router = express.Router();
const jenkins = require('../services/jenkinsService');

// POST /pipeline/start — trigger Jenkins build
// body: { jobName, parameters }
router.post('/start', async (req, res) => {
  try {
    const { jobName = 'devops-lab', parameters = {} } = req.body;
    const result = await jenkins.triggerBuild(jobName, parameters);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /pipeline/status/:jobName — ดู status build ล่าสุด
router.get('/status/:jobName', async (req, res) => {
  try {
    const result = await jenkins.getJobStatus(req.params.jobName);
    res.json({ success: true, data: result });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /pipeline/logs/:jobName — ดู console logs
router.get('/logs/:jobName', async (req, res) => {
  try {
    const logs = await jenkins.getBuildLogs(req.params.jobName);
    res.json({ success: true, data: logs });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /pipeline/jobs — รายการ jobs ทั้งหมด
router.get('/jobs', async (req, res) => {
  try {
    const jobs = await jenkins.listJobs();
    res.json({ success: true, data: jobs });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /pipeline/stages/:jobName — ดู stages ของ pipeline
router.get('/stages/:jobName', async (req, res) => {
  try {
    const stages = await jenkins.getPipelineStages(req.params.jobName);
    res.json({ success: true, data: stages });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

module.exports = router;
