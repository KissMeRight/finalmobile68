const axios = require('axios');

// Jenkins API config จาก .env
const JENKINS_URL = process.env.JENKINS_URL || 'http://localhost:8080';
const JENKINS_USER = process.env.JENKINS_USER || 'admin';
const JENKINS_TOKEN = process.env.JENKINS_TOKEN || '';

// สร้าง Basic Auth header สำหรับ Jenkins API
const authHeader = () => ({
  Authorization: 'Basic ' + Buffer.from(`${JENKINS_USER}:${JENKINS_TOKEN}`).toString('base64'),
});

// Trigger pipeline build
const triggerBuild = async (jobName, parameters = {}) => {
  const url = Object.keys(parameters).length > 0
    ? `${JENKINS_URL}/job/${jobName}/buildWithParameters`
    : `${JENKINS_URL}/job/${jobName}/build`;

  const res = await axios.post(url, null, {
    headers: { ...authHeader(), 'Content-Type': 'application/x-www-form-urlencoded' },
    params: parameters,
    validateStatus: (s) => s < 400,
  });

  // Jenkins คืน Location header ที่ชี้ไป queue item
  const queueUrl = res.headers.location;
  return { triggered: true, jobName, queueUrl };
};

// ดู status ของ job ล่าสุด
const getJobStatus = async (jobName) => {
  const res = await axios.get(
    `${JENKINS_URL}/job/${jobName}/lastBuild/api/json`,
    { headers: authHeader() }
  );
  const build = res.data;
  return {
    jobName,
    buildNumber: build.number,
    result: build.result,           // SUCCESS, FAILURE, ABORTED, null (ยังรัน)
    building: build.building,       // true = กำลังรัน
    duration: Math.round(build.duration / 1000) + 's',
    timestamp: new Date(build.timestamp).toISOString(),
    url: build.url,
  };
};

// ดู logs ของ build ล่าสุด
const getBuildLogs = async (jobName) => {
  const res = await axios.get(
    `${JENKINS_URL}/job/${jobName}/lastBuild/consoleText`,
    { headers: authHeader(), responseType: 'text' }
  );
  return res.data;
};

// ดูรายการ jobs ทั้งหมด
const listJobs = async () => {
  const res = await axios.get(`${JENKINS_URL}/api/json?tree=jobs[name,color,lastBuild[number,result,building]]`, {
    headers: authHeader(),
  });
  return res.data.jobs.map(job => ({
    name: job.name,
    color: job.color,              // blue = success, red = failed, yellow = unstable
    lastBuild: job.lastBuild,
  }));
};

// ดู stages ของ pipeline (ต้องติดตั้ง Pipeline plugin)
const getPipelineStages = async (jobName) => {
  const res = await axios.get(
    `${JENKINS_URL}/job/${jobName}/lastBuild/wfapi/describe`,
    { headers: authHeader() }
  );
  return res.data.stages.map(stage => ({
    name: stage.name,
    status: stage.status,          // SUCCESS, FAILED, IN_PROGRESS, NOT_EXECUTED
    durationMillis: stage.durationMillis,
  }));
};

module.exports = { triggerBuild, getJobStatus, getBuildLogs, listJobs, getPipelineStages };
