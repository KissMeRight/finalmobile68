const k8s = require('@kubernetes/client-node');

const kc = new k8s.KubeConfig();
kc.loadFromDefault();
const appsV1 = kc.makeApiClient(k8s.AppsV1Api);
const coreV1 = kc.makeApiClient(k8s.CoreV1Api);

const NAMESPACE = 'default';
const SERVICE_NAME = 'devops-lab-service';  // K8s Service ที่รับ traffic

// ดู status ปัจจุบันของ Blue/Green
const getStatus = async () => {
  try {
    const svc = await coreV1.readNamespacedService(SERVICE_NAME, NAMESPACE);
    const activeSlot = svc.body.spec.selector?.slot || 'blue';  // blue หรือ green

    // ดู deployment ทั้งสอง
    const [blueRes, greenRes] = await Promise.allSettled([
      appsV1.readNamespacedDeployment(`devops-lab-blue`, NAMESPACE),
      appsV1.readNamespacedDeployment(`devops-lab-green`, NAMESPACE),
    ]);

    const blueInfo = blueRes.status === 'fulfilled' ? {
      ready: blueRes.value.body.status.readyReplicas || 0,
      desired: blueRes.value.body.spec.replicas,
      image: blueRes.value.body.spec.template.spec.containers[0]?.image,
    } : null;

    const greenInfo = greenRes.status === 'fulfilled' ? {
      ready: greenRes.value.body.status.readyReplicas || 0,
      desired: greenRes.value.body.spec.replicas,
      image: greenRes.value.body.spec.template.spec.containers[0]?.image,
    } : null;

    return {
      activeSlot,           // "blue" หรือ "green"
      blue: blueInfo,
      green: greenInfo,
      canSwitch: greenInfo?.ready >= (greenInfo?.desired || 1),  // green พร้อมหรือยัง
    };
  } catch (e) {
    // Mock data สำหรับ demo ถ้า K8s ยังไม่พร้อม
    return {
      activeSlot: 'blue',
      blue: { ready: 1, desired: 1, image: 'devops-lab/app:v1' },
      green: { ready: 1, desired: 1, image: 'devops-lab/app:v2' },
      canSwitch: true,
      mock: true,
    };
  }
};

// สลับ traffic จาก blue ไป green หรือกลับ
const switchTraffic = async (targetSlot) => {
  if (!['blue', 'green'].includes(targetSlot)) {
    throw new Error('targetSlot must be "blue" or "green"');
  }

  // Patch Service selector เพื่อเปลี่ยน traffic
  const patch = {
    spec: {
      selector: { app: 'devops-lab', slot: targetSlot },
    },
  };

  await coreV1.patchNamespacedService(
    SERVICE_NAME, NAMESPACE, patch,
    undefined, undefined, undefined, undefined,
    { headers: { 'Content-Type': 'application/merge-patch+json' } }
  );

  return {
    switched: true,
    activeSlot: targetSlot,
    message: `Traffic switched to ${targetSlot}`,
    timestamp: new Date().toISOString(),
  };
};

// Rollback = switch กลับไปอีก slot
const rollback = async () => {
  const status = await getStatus();
  const rollbackTarget = status.activeSlot === 'blue' ? 'green' : 'blue';
  return switchTraffic(rollbackTarget);
};

module.exports = { getStatus, switchTraffic, rollback };
