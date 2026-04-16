const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
// ต้องมีไฟล์ serviceAccountKey.json จาก Firebase Console
let db;

const initFirebase = () => {
  if (admin.apps.length > 0) return; // ป้องกัน initialize ซ้ำ

  try {
    const serviceAccount = require(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    db = admin.firestore();
    console.log('✅ Firebase initialized');
  } catch (e) {
    console.warn('⚠️  Firebase not configured, using mock data');
  }
};

initFirebase();

// Helper: คืน mock data ถ้า Firebase ไม่พร้อม
const getDb = () => {
  if (!db) throw new Error('Firebase not initialized');
  return db;
};

// ดึง docker images configs จาก Firestore
const getDockerImages = async () => {
  try {
    const snapshot = await getDb().collection('docker_images').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    // Mock data สำหรับ demo
    return [
      { id: '1', name: 'nginx', image: 'nginx:latest', port: 80, category: 'web', difficulty: 'beginner', description: 'Web server' },
      { id: '2', name: 'redis', image: 'redis:alpine', port: 6379, category: 'database', difficulty: 'beginner', description: 'In-memory cache' },
      { id: '3', name: 'node', image: 'node:18-alpine', port: 3000, category: 'runtime', difficulty: 'intermediate', description: 'Node.js runtime' },
      { id: '4', name: 'mysql', image: 'mysql:8', port: 3306, category: 'database', difficulty: 'intermediate', description: 'MySQL database' },
      { id: '5', name: 'postgres', image: 'postgres:15', port: 5432, category: 'database', difficulty: 'intermediate', description: 'PostgreSQL database' },
    ];
  }
};

// ดึง k8s templates จาก Firestore
const getK8sTemplates = async () => {
  try {
    const snapshot = await getDb().collection('k8s_templates').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    return [
      { id: '1', name: 'nginx deployment', image: 'nginx:latest', replicas: 1, port: 80, difficulty: 'beginner' },
      { id: '2', name: 'node app', image: 'node:18-alpine', replicas: 2, port: 3000, difficulty: 'intermediate' },
    ];
  }
};

// ดึง pipeline configs
const getPipelines = async () => {
  try {
    const snapshot = await getDb().collection('pipelines').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    return [
      { id: '1', name: 'deploy-nginx', jobName: 'devops-lab', steps: ['build', 'test', 'push', 'deploy'], difficulty: 'beginner' },
    ];
  }
};

// ดึง tutorials
const getTutorials = async () => {
  try {
    const snapshot = await getDb().collection('tutorials').orderBy('order').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    return [
      { id: '1', title: 'Docker Basics', level: 'beginner', order: 1 },
      { id: '2', title: 'Kubernetes 101', level: 'intermediate', order: 2 },
      { id: '3', title: 'CI/CD with Jenkins', level: 'intermediate', order: 3 },
      { id: '4', title: 'Blue-Green Deployment', level: 'advanced', order: 4 },
    ];
  }
};

module.exports = { getDockerImages, getK8sTemplates, getPipelines, getTutorials };
