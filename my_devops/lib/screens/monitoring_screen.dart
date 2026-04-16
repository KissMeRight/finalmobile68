import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  Map<String, dynamic> _metrics = {};
  List<dynamic> _podMetrics = [];
  bool _loading = true;

  // เก็บ history สำหรับ chart (สูงสุด 20 จุด)
  final List<double> _cpuHistory = [];
  final List<double> _memHistory = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // auto-refresh ทุก 10 วินาที
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final clusterMetrics = await ApiService.getClusterMetrics();
      final podMetrics = await ApiService.getPodMetrics();
      final metrics = Map<String, dynamic>.from(clusterMetrics);

      // เพิ่ม history สำหรับ chart
      final cpu = double.tryParse(metrics['cpu']?.toString() ?? '0') ?? 0;
      final mem = double.tryParse(metrics['memory']?.toString() ?? '0') ?? 0;
      if (_cpuHistory.length >= 20) _cpuHistory.removeAt(0);
      if (_memHistory.length >= 20) _memHistory.removeAt(0);
      _cpuHistory.add(cpu);
      _memHistory.add(mem);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _podMetrics = podMetrics;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.monitor_heart, color: AppTheme.green, size: 20),
            const SizedBox(width: 8),
            const Text('Monitoring'),
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
                    // Status banner
                    if (_metrics['mock'] == true) _buildMockBanner(),
                    const SizedBox(height: 4),

                    // Metric cards
                    const SectionHeader('Cluster Resources'),
                    _buildMetricCards(),
                    const SizedBox(height: 20),

                    // CPU chart
                    const SectionHeader('CPU Usage (%)'),
                    _buildLineChart(_cpuHistory, AppTheme.blue, 100),
                    const SizedBox(height: 20),

                    // Memory chart
                    const SectionHeader('Memory Usage (%)'),
                    _buildLineChart(_memHistory, AppTheme.secondary, 100),
                    const SizedBox(height: 20),

                    // Pod metrics
                    const SectionHeader('Pod CPU Usage'),
                    _buildPodList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMockBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.amber, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Demo mode — Connect Prometheus to see real metrics',
              style: TextStyle(color: AppTheme.amber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    final cpu = _metrics['cpu']?.toString() ?? '--';
    final mem = _metrics['memory']?.toString() ?? '--';
    final pods = _metrics['runningPods']?.toString() ?? '--';

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        _metricCard('CPU', '$cpu%', AppTheme.blue, Icons.memory),
        _metricCard('Memory', '$mem%', AppTheme.secondary, Icons.storage),
        _metricCard('Pods', pods, AppTheme.green, Icons.hub),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<double> data, Color color, double maxY) {
    if (data.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: const Center(
          child: Text(
            'Collecting data...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final spots =
        data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 19,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine:
                (v) => FlLine(
                  color: AppTheme.textSecondary.withOpacity(0.1),
                  strokeWidth: 0.5,
                ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget:
                    (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodList() {
    if (_podMetrics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No pod metrics available',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _podMetrics.length,
        separatorBuilder:
            (_, __) => const Divider(color: Color(0xFF30363D), height: 1),
        itemBuilder: (_, i) {
          final p = _podMetrics[i] as Map<String, dynamic>;
          final cpu = double.tryParse(p['cpu']?.toString() ?? '0') ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.circle, color: AppTheme.green, size: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p['pod'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(cpu * 1000).toStringAsFixed(1)} m',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
