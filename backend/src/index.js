require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Import routes
const dockerRoutes = require('./routes/docker');
const k8sRoutes = require('./routes/kubernetes');
const pipelineRoutes = require('./routes/pipeline');
const monitoringRoutes = require('./routes/monitoring');
const bluegreenRoutes = require('./routes/bluegreen');
const firebaseRoutes = require('./routes/firebase');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());                          // อนุญาต Flutter เรียก API
app.use(express.json());                  // รับ JSON body
app.use(morgan('dev'));                   // Log requests

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/docker', dockerRoutes);         // Docker API
app.use('/k8s', k8sRoutes);              // Kubernetes API
app.use('/pipeline', pipelineRoutes);     // Jenkins CI/CD
app.use('/monitoring', monitoringRoutes); // Prometheus metrics
app.use('/bluegreen', bluegreenRoutes);   // Blue-Green deployment
app.use('/firebase', firebaseRoutes);     // Firebase data

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message });
});

app.listen(PORT, () => {
  console.log(`✅ DevOps Lab Backend running on port ${PORT}`);
});
