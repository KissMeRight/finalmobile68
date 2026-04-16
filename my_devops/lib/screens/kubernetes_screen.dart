import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class KubernetesScreen extends StatefulWidget {
  const KubernetesScreen({super.key});

  @override
  State<KubernetesScreen> createState() => _KubernetesScreenState();
}

class _KubernetesScreenState extends State<KubernetesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _nodes = [];
  List<dynamic> _pods = [];
  List<dynamic> _deployments = [];
  List<dynamic> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final nodes = await ApiService.getNodes();
      final pods = await ApiService.getPods();
      final deployments = await ApiService.getDeployments();
      final services = await ApiService.getServices();
      setState(() {
        _nodes = nodes;
        _pods = pods;
        _deployments = deployments;
        _services = services;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  // ── Confirm Delete Dialog ─────────────────────────────────
  Future<bool> _confirmDelete(String kind, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgCard,
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 22),
              const SizedBox(width: 8),
              Text('Delete $kind',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('จะลบ:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.red.withOpacity(0.4)),
                ),
                child: Text(name,
                    style: const TextStyle(
                        color: AppTheme.red, fontFamily: 'monospace', fontSize: 13)),
              ),
              if (kind == 'Deployment') ...[
                const SizedBox(height: 10),
                const Text('⚠️ Pods ทั้งหมดจะถูกลบตามด้วย',
                    style: TextStyle(color: AppTheme.amber, fontSize: 12)),
              ],
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red.withOpacity(0.15),
                  foregroundColor: AppTheme.red,
                  side: BorderSide(color: AppTheme.red.withOpacity(0.4)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Delete Actions ────────────────────────────────────────
  Future<void> _deletePod(String name) async {
    if (!await _confirmDelete('Pod', name)) return;
    try {
      await ApiService.deletePod(name);
      _showSnack('🗑️ Deleted pod: $name');
      _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteDeployment(String name) async {
    if (!await _confirmDelete('Deployment', name)) return;
    try {
      await ApiService.deleteDeployment(name);
      _showSnack('🗑️ Deleted deployment: $name');
      _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteService(String name) async {
    if (!await _confirmDelete('Service', name)) return;
    try {
      await ApiService.deleteService(name);
      _showSnack('🗑️ Deleted service: $name');
      _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _restartDeployment(String name) async {
    try {
      await ApiService.restartDeployment(name);
      _showSnack('🔄 Restarting: $name');
      await Future.delayed(const Duration(seconds: 2));
      _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showDeployDialog() {
    final nameCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    int replicas = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Deploy Application',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameCtrl, 'App name (e.g. nginx-app)'),
          const SizedBox(height: 12),
          _field(imageCtrl, 'Image (e.g. nginx:latest)'),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Replicas:', style: TextStyle(color: AppTheme.textSecondary)),
            const Spacer(),
            StatefulBuilder(builder: (_, setS) => Row(children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: replicas > 1 ? () => setS(() => replicas--) : null,
                color: AppTheme.textSecondary,
              ),
              Text('$replicas',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => setS(() => replicas++),
                color: AppTheme.primary,
              ),
            ])),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deployApp(nameCtrl.text, imageCtrl.text, replicas, 80);
              _showSnack('✅ Deploying ${nameCtrl.text}...');
              await Future.delayed(const Duration(seconds: 2));
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Deploy'),
          ),
        ],
      ),
    );
  }

  Future<void> _scale(String name, int current) async {
    int replicas = current;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Scale: $name',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: StatefulBuilder(builder: (_, setS) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: replicas > 0 ? () => setS(() => replicas--) : null,
              color: AppTheme.textSecondary,
            ),
            Text('$replicas',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setS(() => replicas++),
              color: AppTheme.primary,
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.scaleDeployment(name, replicas);
              _showSnack('✅ Scaled $name to $replicas replicas');
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: const Text('Scale'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF30363D))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF30363D))),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.red : AppTheme.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.hub, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          const Text('Kubernetes'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showDeployDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondary,
          isScrollable: true,
          tabs: [
            Tab(text: 'Nodes (${_nodes.length})'),
            Tab(text: 'Pods (${_pods.length})'),
            Tab(text: 'Deploys (${_deployments.length})'),
            Tab(text: 'Services (${_services.length})'),
          ],
        ),
      ),
      body: _loading
          ? const CenteredLoading()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNodes(),
                _buildPods(),
                _buildDeployments(),
                _buildServices(),
              ],
            ),
    );
  }

  Widget _buildNodes() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nodes.length,
      itemBuilder: (_, i) {
        final n = _nodes[i] as Map;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.computer, color: AppTheme.secondary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['name'] ?? '',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('CPU: ${n['cpu']}  •  RAM: ${n['memory']}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('Version: ${n['version'] ?? '--'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              StatusBadge(n['status'] ?? 'Unknown'),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildPods() {
    if (_pods.isEmpty) {
      return const EmptyState(message: 'No pods found', icon: Icons.hub_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pods.length,
      itemBuilder: (_, i) {
        final p = _pods[i] as Map;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(p['name'] ?? '',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(p['status'] ?? 'Unknown'),
                ]),
                const SizedBox(height: 4),
                Text(p['image'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis),
                Text('Node: ${p['node'] ?? '--'}  •  Restarts: ${p['restarts'] ?? 0}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ])),
              // ── ⋮ Menu ──
              PopupMenuButton<String>(
                color: AppTheme.bgSurface,
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                onSelected: (val) {
                  if (val == 'delete') _deletePod(p['name'] ?? '');
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: AppTheme.red, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.red)),
                    ]),
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDeployments() {
    if (_deployments.isEmpty) {
      return Column(children: [
        const SizedBox(height: 20),
        const EmptyState(
            message: 'No deployments\nTap + to deploy',
            icon: Icons.rocket_launch_outlined),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deployments.length,
      itemBuilder: (_, i) {
        final d = _deployments[i] as Map;
        final ready = d['readyReplicas'] ?? 0;
        final desired = d['replicas'] ?? 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.rocket_launch, color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(d['image'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis),
                ])),
                StatusBadge(ready >= desired ? 'ready' : 'pending'),
                // ── ⋮ Menu ──
                PopupMenuButton<String>(
                  color: AppTheme.bgSurface,
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  onSelected: (val) {
                    if (val == 'scale') _scale(d['name'] ?? '', desired);
                    if (val == 'restart') _restartDeployment(d['name'] ?? '');
                    if (val == 'delete') _deleteDeployment(d['name'] ?? '');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'scale',
                      child: Row(children: [
                        Icon(Icons.tune, color: AppTheme.primary, size: 16),
                        SizedBox(width: 8),
                        Text('Scale', style: TextStyle(color: AppTheme.textPrimary)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'restart',
                      child: Row(children: [
                        Icon(Icons.refresh, color: AppTheme.amber, size: 16),
                        SizedBox(width: 8),
                        Text('Restart', style: TextStyle(color: AppTheme.textPrimary)),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: AppTheme.red, size: 16),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.red)),
                      ]),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Replicas: ',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('$ready/$desired',
                    style: TextStyle(
                        color: ready >= desired ? AppTheme.green : AppTheme.amber,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: desired > 0 ? (ready / desired).clamp(0.0, 1.0) : 0,
                backgroundColor: AppTheme.bgSurface,
                valueColor: AlwaysStoppedAnimation(
                    ready >= desired ? AppTheme.green : AppTheme.amber),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildServices() {
    if (_services.isEmpty) {
      return const EmptyState(message: 'No services', icon: Icons.dns_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i] as Map;
        final isSystem = s['name'] == 'kubernetes';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(children: [
              const Icon(Icons.dns, color: AppTheme.amber, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('${s['type']}  •  ${s['clusterIP'] ?? '--'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if ((s['ports'] as List?)?.isNotEmpty == true)
                  Text('Ports: ${(s['ports'] as List).join(', ')}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              // ── ⋮ Menu (ซ่อนถ้าเป็น system service) ──
              if (!isSystem)
                PopupMenuButton<String>(
                  color: AppTheme.bgSurface,
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  onSelected: (val) {
                    if (val == 'delete') _deleteService(s['name'] ?? '');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: AppTheme.red, size: 16),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.red)),
                      ]),
                    ),
                  ],
                ),
            ]),
          ),
        );
      },
    );
  }
}