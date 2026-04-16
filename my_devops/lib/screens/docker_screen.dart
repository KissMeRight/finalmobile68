import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class DockerScreen extends StatefulWidget {
  const DockerScreen({super.key});

  @override
  State<DockerScreen> createState() => _DockerScreenState();
}

class _DockerScreenState extends State<DockerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _availableImages = []; // จาก Firebase (catalog)
  List<dynamic> _containers = []; // จาก Docker daemon
  bool _loading = true;
  String? _runningImage; // image ที่กำลัง run อยู่

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final results = await Future.wait([
        ApiService.getDockerImages(),
        ApiService.getContainers(),
      ]);
      setState(() {
        _availableImages = results[0];
        _containers = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _runContainer(Map image) async {
    setState(() => _runningImage = image['image']);
    try {
      await ApiService.runContainer(
        image['image'],
        name: '${image['name']}-lab',
        port: image['port'] ?? 80,
      );
      _showSnack('✅ Container started: ${image['name']}');
      await _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _runningImage = null);
    }
  }

  Future<void> _stopContainer(String containerId, String name) async {
    try {
      await ApiService.stopContainer(containerId);
      _showSnack('🛑 Container stopped: $name');
      await _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  void _viewLogs(String containerId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ContainerLogsScreen(containerId: containerId, name: name),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.red : AppTheme.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.inventory_2, color: AppTheme.blue, size: 20),
            const SizedBox(width: 8),
            const Text('Docker Lab'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.blue,
          tabs: [
            Tab(text: 'Images (${_availableImages.length})'),
            Tab(text: 'Containers (${_containers.length})'),
          ],
        ),
      ),
      body:
          _loading
              ? const CenteredLoading()
              : TabBarView(
                controller: _tabController,
                children: [_buildImagesTab(), _buildContainersTab()],
              ),
    );
  }

  // Tab 1: รายการ images ที่รันได้
  Widget _buildImagesTab() {
    if (_availableImages.isEmpty) {
      return const EmptyState(
        message: 'No images available',
        icon: Icons.inventory_2_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableImages.length,
      itemBuilder: (_, i) {
        final img = _availableImages[i] as Map;
        final isRunning = _runningImage == img['image'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.layers_outlined,
                        color: AppTheme.blue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            img['name'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            img['image'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _difficultyBadge(img['difficulty'] ?? 'beginner'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  img['description'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Port: ${img['port'] ?? '--'}  •  Category: ${img['category'] ?? '--'}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        label: 'Run Container',
                        icon: Icons.play_arrow,
                        color: AppTheme.green,
                        isLoading: isRunning,
                        onPressed: () => _runContainer(img),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 2: containers ที่รันอยู่
  Widget _buildContainersTab() {
    if (_containers.isEmpty) {
      return const EmptyState(
        message: 'No containers running\nGo to Images tab to run one',
        icon: Icons.view_in_ar_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _containers.length,
      itemBuilder: (_, i) {
        final c = _containers[i] as Map;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.view_in_ar,
                      color: AppTheme.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c['name'] ?? c['id'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusBadge(c['state'] ?? 'unknown'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c['image'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                if ((c['ports'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ports: ${(c['ports'] as List).join(', ')}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    ActionButton(
                      label: 'Logs',
                      icon: Icons.terminal,
                      color: AppTheme.secondary,
                      onPressed: () => _viewLogs(c['id'], c['name'] ?? ''),
                    ),
                    const SizedBox(width: 8),
                    if (c['state'] == 'running')
                      ActionButton(
                        label: 'Stop',
                        icon: Icons.stop,
                        color: AppTheme.red,
                        onPressed:
                            () => _stopContainer(c['id'], c['name'] ?? ''),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _difficultyBadge(String level) {
    final colors = {
      'beginner': AppTheme.green,
      'intermediate': AppTheme.amber,
      'advanced': AppTheme.red,
    };
    final color = colors[level] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Container Logs Screen ────────────────────────────────────────────────────
class ContainerLogsScreen extends StatefulWidget {
  final String containerId;
  final String name;
  const ContainerLogsScreen({
    super.key,
    required this.containerId,
    required this.name,
  });

  @override
  State<ContainerLogsScreen> createState() => _ContainerLogsScreenState();
}

class _ContainerLogsScreenState extends State<ContainerLogsScreen> {
  String _logs = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await ApiService.getContainerLogs(widget.containerId);
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _logs = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs: ${widget.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body:
          _loading
              ? const CenteredLoading()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: SelectableText(
                    _logs.isEmpty ? 'No logs available' : _logs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
    );
  }
}
