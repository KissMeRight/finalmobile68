import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _bgStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getClusterMetrics(),
        ApiService.getBlueGreenStatus(),
      ]);
      setState(() {
        _metrics = Map<String, dynamic>.from(results[0]);
        _bgStatus = Map<String, dynamic>.from(results[1]);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DevOps Lab'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadData,
        child:
            _loading
                ? const CenteredLoading()
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBanner(),
                    const SizedBox(height: 20),
                    const SectionHeader('Cluster Overview'),
                    _buildMetricsGrid(),
                    const SizedBox(height: 20),
                    const SectionHeader('Blue-Green Status'),
                    _buildBlueGreenCard(),
                    const SizedBox(height: 20),
                    const SectionHeader('Quick Actions'),
                    _buildQuickActions(),
                  ],
                ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DevOps Learning Lab',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Docker · Kubernetes · Jenkins · ArgoCD · Monitoring',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            // ✅ เปลี่ยน Row → Wrap กัน overflow
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge('Docker', AppTheme.blue),
              _buildBadge('K8s', AppTheme.secondary),
              _buildBadge('Jenkins', AppTheme.amber),
              _buildBadge('ArgoCD', AppTheme.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final cpu = _metrics['cpu']?.toString() ?? '--';
    final memory = _metrics['memory']?.toString() ?? '--';
    final pods = _metrics['runningPods']?.toString() ?? '--';
    final isMock = _metrics['mock'] == true;

    // ✅ เปลี่ยนจาก GridView → Column + Row ให้การ์ดขยายตามเนื้อหาได้เลย
    final cards = [
      InfoCard(
        title: 'CPU Usage',
        value: '$cpu%',
        icon: Icons.memory,
        color: AppTheme.blue,
      ),
      InfoCard(
        title: 'Memory Usage',
        value: '$memory%',
        icon: Icons.storage,
        color: AppTheme.secondary,
      ),
      InfoCard(
        title: 'Running Pods',
        value: pods,
        icon: Icons.hub,
        color: AppTheme.green,
      ),
      InfoCard(
        title: 'Active Slot',
        value: _bgStatus['activeSlot']?.toString().toUpperCase() ?? '--',
        icon: Icons.swap_horiz,
        color: AppTheme.primary,
      ),
    ];

    return Column(
      children: [
        if (isMock)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppTheme.amber, size: 14),
                SizedBox(width: 6),
                Text(
                  'Demo mode — Prometheus not connected',
                  style: TextStyle(color: AppTheme.amber, fontSize: 12),
                ),
              ],
            ),
          ),
        // ✅ Row แรก
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ✅ Row สอง
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlueGreenCard() {
    final activeSlot = _bgStatus['activeSlot'] ?? 'blue';
    final blue = _bgStatus['blue'] as Map? ?? {};
    final green = _bgStatus['green'] as Map? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSlotIndicator(
                  'Blue',
                  AppTheme.blueSlot,
                  activeSlot == 'blue',
                  blue['image']?.toString() ?? '—',
                ),
                const SizedBox(width: 8), // ✅ ใช้ SizedBox แทน Spacer
                const Icon(Icons.swap_horiz, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                _buildSlotIndicator(
                  'Green',
                  AppTheme.greenSlot,
                  activeSlot == 'green',
                  green['image']?.toString() ?? '—',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Traffic → ${activeSlot.toUpperCase()}',
                style: TextStyle(
                  color:
                      activeSlot == 'blue'
                          ? AppTheme.blueSlot
                          : AppTheme.greenSlot,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotIndicator(
    String slot,
    Color color,
    bool isActive,
    String image,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : AppTheme.bgSurface,
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  // ✅ เพิ่ม Flexible กัน overflow
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(color: color, fontSize: 9),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              image,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8, // ✅ ปรับให้พอดี
      children: [
        _quickAction(
          'Docker Lab',
          Icons.inventory_2_outlined,
          AppTheme.blue,
          1,
        ),
        _quickAction('K8s Cluster', Icons.hub_outlined, AppTheme.secondary, 2),
        _quickAction(
          'CI/CD Pipeline',
          Icons.play_circle_outline,
          AppTheme.amber,
          3,
        ),
        _quickAction(
          'Monitoring',
          Icons.monitor_heart_outlined,
          AppTheme.green,
          4,
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, int navIndex) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              // ✅ เพิ่ม Flexible กัน overflow
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
