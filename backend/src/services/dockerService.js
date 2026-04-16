const Docker = require('dockerode');

// เชื่อมต่อ Docker daemon ที่รันบนเครื่อง
// socketPath: '/var/run/docker.sock' = Linux/Mac
// host + port = Docker TCP (ถ้าเปิด TCP)
const docker = new Docker({
  socketPath: '//./pipe/docker_engine'
});

// ดึงรายการ images ที่มีบนเครื่อง
const listImages = async () => {
  const images = await docker.listImages({ all: false });
  return images.map(img => ({
    id: img.Id.substring(7, 19),          // ย่อ ID
    tags: img.RepoTags || ['<none>'],
    size: Math.round(img.Size / 1024 / 1024) + ' MB',
    created: new Date(img.Created * 1000).toLocaleDateString(),
  }));
};

// ดึงรายการ containers ที่รันอยู่
const listContainers = async () => {
  const containers = await docker.listContainers({ all: true });
  return containers.map(c => ({
    id: c.Id.substring(0, 12),
    name: c.Names[0].replace('/', ''),
    image: c.Image,
    status: c.Status,
    state: c.State,                        // running, exited, paused
    ports: c.Ports.map(p => `${p.PublicPort || ''}:${p.PrivatePort}/${p.Type}`).filter(Boolean),
  }));
};

// รัน container จาก image name
const runContainer = async ({ image, name, ports }) => {
  // ports format: { '80/tcp': [{ HostPort: '8080' }] }
  const portBindings = {};
  const exposedPorts = {};

  if (ports) {
    Object.entries(ports).forEach(([containerPort, hostConfig]) => {
      portBindings[containerPort] = hostConfig;
      exposedPorts[containerPort] = {};
    });
  }

  const container = await docker.createContainer({
    Image: image,
    name: name || undefined,
    ExposedPorts: exposedPorts,
    HostConfig: { PortBindings: portBindings },
  });

  await container.start();
  const info = await container.inspect();

  return {
    id: info.Id.substring(0, 12),
    name: info.Name.replace('/', ''),
    image: info.Config.Image,
    status: info.State.Status,
  };
};

// หยุด container
const stopContainer = async (containerId) => {
  const container = docker.getContainer(containerId);
  await container.stop();
  return { stopped: containerId };
};

// ลบ container
const removeContainer = async (containerId) => {
  const container = docker.getContainer(containerId);
  await container.remove({ force: true });
  return { removed: containerId };
};

// ดู logs ของ container
const getContainerLogs = async (containerId) => {
  const container = docker.getContainer(containerId);
  const logs = await container.logs({
    stdout: true, stderr: true, tail: 50,
  });
  return logs.toString('utf8');
};

module.exports = { listImages, listContainers, runContainer, stopContainer, removeContainer, getContainerLogs };
