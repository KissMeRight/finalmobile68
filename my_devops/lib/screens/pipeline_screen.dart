import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  Map<String, dynamic> _pipelineStatus = {};
  List<dynamic> _stages = [];
  Map<String, dynamic> _bgStatus = {};
  bool _loading = true;
  bool _triggering = false;
  bool _switching = false;
  Timer? _pollTimer;

  static const jobName = 'devops-lab';

  @override
  void initState() {
    super.initState();
    _loadData();
    // Poll สถานะ pipeline ทุก 5 วินาที ระหว่าง building
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pipelineStatus['building'] == true) _loadData();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // ดึงข้อมูลแยกกันเพื่อให้ Dart รู้ Type ที่แน่นอน
      final status = await ApiService.getPipelineStatus(jobName);
      final stages = await ApiService.getPipelineStages(jobName);
      final bg = await ApiService.getBlueGreenStatus();

      if (mounted) {
        setState(() {
          _pipelineStatus = Map<String, dynamic>.from(status);
          _stages = List<dynamic>.from(stages); // แก้ไขตรงนี้
          _bgStatus = Map<String, dynamic>.from(bg);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _triggerPipeline() async {
    setState(() => _triggering = true);
    try {
      await ApiService.triggerPipeline(jobName: jobName);
      _showSnack('🚀 Pipeline triggered!');
      await Future.delayed(const Duration(seconds: 2));
      await _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _triggering = false);
    }
  }

  Future<void> _switchTraffic(String slot) async {
    setState(() => _switching = true);
    try {
      await ApiService.switchTraffic(slot);
      _showSnack('✅ Traffic switched to ${slot.toUpperCase()}');
      await _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _switching = false);
    }
  }

  Future<void> _rollback() async {
    setState(() => _switching = true);
    try {
      await ApiService.rollback();
      _showSnack('🔄 Rolled back successfully');
      await _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _switching = false);
    }
  }

  void _viewLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PipelineLogsScreen(jobName: jobName)),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.red : AppTheme.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.play_circle, color: AppTheme.amber, size: 20),
            const SizedBox(width: 8),
            const Text('CI/CD Pipeline'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _loading
              ? const CenteredLoading()
              : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pipeline control
                    _buildPipelineCard(),
                    const SizedBox(height: 16),

                    // Stage progress
                    const SectionHeader('Pipeline Stages'),
                    _buildStagesCard(),
                    const SizedBox(height: 16),

                    // Blue-Green control
                    const SectionHeader('🔵🟢 Blue-Green Deployment'),
                    _buildBlueGreenCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildPipelineCard() {
    final building = _pipelineStatus['building'] == true;
    final result = _pipelineStatus['result']?.toString() ?? 'N/A';
    final buildNum = _pipelineStatus['buildNumber']?.toString() ?? '--';
    final duration = _pipelineStatus['duration']?.toString() ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jenkins Pipeline',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Build #$buildNum  •  $duration',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (building)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.amber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Running...',
                        style: TextStyle(color: AppTheme.amber, fontSize: 12),
                      ),
                    ],
                  )
                else
                  StatusBadge(result.toLowerCase()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: building ? 'Running...' : 'Trigger Build',
                    icon: Icons.play_arrow,
                    color: AppTheme.amber,
                    isLoading: _triggering,
                    onPressed: building ? () {} : _triggerPipeline,
                  ),
                ),
                const SizedBox(width: 8),
                ActionButton(
                  label: 'Logs',
                  icon: Icons.terminal,
                  color: AppTheme.secondary,
                  onPressed: _viewLogs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagesCard() {
    // Mock stages ถ้า Jenkins ยังไม่ได้ setup
    final stages =
        _stages.isNotEmpty
            ? _stages
            : [
              {'name': 'Build Image', 'status': 'SUCCESS'},
              {'name': 'Run Tests', 'status': 'SUCCESS'},
              {'name': 'Push Image', 'status': 'SUCCESS'},
              {'name': 'Update Manifest', 'status': 'IN_PROGRESS'},
              {'name': 'ArgoCD Deploy', 'status': 'NOT_EXECUTED'},
            ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              stages.asMap().entries.map((entry) {
                final i = entry.key;
                // แก้ไขการ Cast ตรงนี้
                final s = entry.value as Map<String, dynamic>;
                final isLast = i == stages.length - 1;
                return _buildStageRow(
                  s['name']?.toString() ?? '',
                  s['status']?.toString() ?? 'NOT_EXECUTED',
                  isLast: isLast,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageRow(String name, String status, {bool isLast = false}) {
    final color =
        status == 'SUCCESS'
            ? AppTheme.green
            : status == 'IN_PROGRESS'
            ? AppTheme.amber
            : status == 'FAILED'
            ? AppTheme.red
            : AppTheme.textSecondary.withOpacity(0.4);

    final icon =
        status == 'SUCCESS'
            ? Icons.check_circle
            : status == 'IN_PROGRESS'
            ? Icons.radio_button_checked
            : status == 'FAILED'
            ? Icons.cancel
            : Icons.radio_button_unchecked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 20),
            if (!isLast)
              Container(width: 2, height: 36, color: color.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color:
                      status == 'NOT_EXECUTED'
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                status.replaceAll('_', ' '),
                style: TextStyle(color: color, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlueGreenCard() {
    final activeSlot = _bgStatus['activeSlot']?.toString() ?? 'blue';
    final blue = _bgStatus['blue'] as Map<String, dynamic>? ?? {};
    final green = _bgStatus['green'] as Map<String, dynamic>? ?? {};
    final canSwitch = _bgStatus['canSwitch'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot status
            Row(
              children: [
                Expanded(
                  child: _slotCard(
                    'Blue',
                    AppTheme.blueSlot,
                    activeSlot == 'blue',
                    blue['image']?.toString() ?? '—',
                    '${blue['ready'] ?? 0}/${blue['desired'] ?? 1} ready',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _slotCard(
                    'Green',
                    AppTheme.greenSlot,
                    activeSlot == 'green',
                    green['image']?.toString() ?? '—',
                    '${green['ready'] ?? 0}/${green['desired'] ?? 1} ready',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Traffic label
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Traffic → ${activeSlot.toUpperCase()}',
                    style: TextStyle(
                      color:
                          activeSlot == 'blue'
                              ? AppTheme.blueSlot
                              : AppTheme.greenSlot,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label:
                        activeSlot == 'blue'
                            ? 'Switch to Green'
                            : 'Switch to Blue',
                    icon: Icons.swap_horiz,
                    color:
                        activeSlot == 'blue'
                            ? AppTheme.greenSlot
                            : AppTheme.blueSlot,
                    isLoading: _switching,
                    onPressed:
                        canSwitch
                            ? () => _switchTraffic(
                              activeSlot == 'blue' ? 'green' : 'blue',
                            )
                            : () => _showSnack('Green is not ready yet'),
                  ),
                ),
                const SizedBox(width: 8),
                ActionButton(
                  label: 'Rollback',
                  icon: Icons.undo,
                  color: AppTheme.red,
                  isLoading: _switching,
                  onPressed: _rollback,
                ),
              ],
            ),
            if (!canSwitch) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ Green environment not ready. Deploy first via Jenkins.',
                style: TextStyle(color: AppTheme.amber, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _slotCard(
    String slot,
    Color color,
    bool isActive,
    String image,
    String ready,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : const Color(0xFF30363D),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                slot,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            image,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            ready,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Pipeline Logs Screen ─────────────────────────────────────────────────────
class PipelineLogsScreen extends StatefulWidget {
  final String jobName;
  const PipelineLogsScreen({super.key, required this.jobName});

  @override
  State<PipelineLogsScreen> createState() => _PipelineLogsScreenState();
}

class _PipelineLogsScreenState extends State<PipelineLogsScreen> {
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
      final logs = await ApiService.getPipelineLogs(widget.jobName);
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _logs = 'Error loading logs: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pipeline Logs: ${widget.jobName}'),
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
                      fontSize: 11,
                      color: Color(0xFF7EE787),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
    );
  }
}
