const k8s = require('@kubernetes/client-node');

const kc = new k8s.KubeConfig();
kc.loadFromDefault();

const coreV1 = kc.makeApiClient(k8s.CoreV1Api);
const appsV1 = kc.makeApiClient(k8s.AppsV1Api);

const NAMESPACE = 'default';

const getPods = async () => {
  const res = await coreV1.listNamespacedPod(NAMESPACE);
  return res.body.items.map(pod => ({
    name: pod.metadata.name,
    namespace: pod.metadata.namespace,
    status: pod.status.phase,
    ready: pod.status.containerStatuses ? pod.status.containerStatuses[0]?.ready : false,
    restarts: pod.status.containerStatuses ? pod.status.containerStatuses[0]?.restartCount : 0,
    node: pod.spec.nodeName,
    image: pod.spec.containers[0]?.image,
    createdAt: pod.metadata.creationTimestamp,
  }));
};

const getNodes = async () => {
  const res = await coreV1.listNode();
  return res.body.items.map(node => ({
    name: node.metadata.name,
    status: node.status.conditions?.find(c => c.type === 'Ready')?.status === 'True' ? 'Ready' : 'NotReady',
    roles: Object.keys(node.metadata.labels || {}).filter(k => k.startsWith('node-role.kubernetes.io/')).map(k => k.split('/')[1]),
    version: node.status.nodeInfo?.kubeletVersion,
    cpu: node.status.capacity?.cpu,
    memory: node.status.capacity?.memory,
  }));
};

const getDeployments = async () => {
  const res = await appsV1.listNamespacedDeployment(NAMESPACE);
  return res.body.items.map(dep => ({
    name: dep.metadata.name,
    namespace: dep.metadata.namespace,
    replicas: dep.spec.replicas,
    readyReplicas: dep.status.readyReplicas || 0,
    image: dep.spec.template.spec.containers[0]?.image,
    labels: dep.metadata.labels,
    createdAt: dep.metadata.creationTimestamp,
  }));
};

const getServices = async () => {
  const res = await coreV1.listNamespacedService(NAMESPACE);
  return res.body.items.map(svc => ({
    name: svc.metadata.name,
    type: svc.spec.type,
    clusterIP: svc.spec.clusterIP,
    ports: svc.spec.ports?.map(p => `${p.port}:${p.targetPort}/${p.protocol}`),
    selector: svc.spec.selector,
  }));
};

const deployApp = async (deploymentManifest) => {
  try {
    const res = await appsV1.createNamespacedDeployment(NAMESPACE, deploymentManifest);
    return { created: res.body.metadata.name };
  } catch (e) {
    if (e.statusCode === 409) {
      const name = deploymentManifest.metadata.name;
      const res = await appsV1.replaceNamespacedDeployment(name, NAMESPACE, deploymentManifest);
      return { updated: res.body.metadata.name };
    }
    throw e;
  }
};

const scaleDeployment = async (name, replicas) => {
  const patch = { spec: { replicas: parseInt(replicas) } };
  const res = await appsV1.patchNamespacedDeployment(
    name, NAMESPACE, patch,
    undefined, undefined, undefined, undefined,
    { headers: { 'Content-Type': 'application/merge-patch+json' } }
  );
  return { name: res.body.metadata.name, replicas: res.body.spec.replicas };
};

// ── DELETE ──────────────────────────────────────────────────
const deletePod = async (name) => {
  await coreV1.deleteNamespacedPod(name, NAMESPACE);
  return { deleted: name, kind: 'Pod' };
};

const deleteDeployment = async (name) => {
  await appsV1.deleteNamespacedDeployment(name, NAMESPACE);
  return { deleted: name, kind: 'Deployment' };
};

const deleteService = async (name) => {
  await coreV1.deleteNamespacedService(name, NAMESPACE);
  return { deleted: name, kind: 'Service' };
};

const restartDeployment = async (name) => {
  const patch = {
    spec: {
      template: {
        metadata: {
          annotations: { 'kubectl.kubernetes.io/restartedAt': new Date().toISOString() },
        },
      },
    },
  };
  await appsV1.patchNamespacedDeployment(
    name, NAMESPACE, patch,
    undefined, undefined, undefined, undefined,
    { headers: { 'Content-Type': 'application/merge-patch+json' } }
  );
  return { restarted: name };
};

module.exports = {
  getPods, getNodes, getDeployments, getServices,
  deployApp, scaleDeployment,
  deletePod, deleteDeployment, deleteService, restartDeployment,
};