import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // ────────────────────────────────────────────────────────
  // แก้ baseUrl ตาม device ที่ใช้:
  //   Android Emulator  → http://10.0.2.2:3000
  //   iOS Simulator     → http://localhost:3000
  //   Physical device   → http://<IP เครื่อง>:3000  เช่น http://192.168.1.5:3000
  //   Windows/macOS app → http://localhost:3000
  // ────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:3000';

  static final _client = http.Client();

  // Helper: GET request พร้อม error message ชัดเจน
  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 400) {
        throw Exception('Server error ${res.statusCode}: ${res.body}');
      }
      return jsonDecode(res.body);
    } on TimeoutException {
      throw Exception(
        'Connection timeout\nตรวจสอบ:\n1. รัน: cd backend && npm run dev\n2. baseUrl ถูกต้องไหม? → $baseUrl',
      );
    } on SocketException catch (e) {
      throw Exception('เชื่อมต่อไม่ได้: ${e.message}\nbaseUrl: $baseUrl');
    }
  }

  // Helper: POST request
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 400) {
        throw Exception('Server error ${res.statusCode}: ${res.body}');
      }
      return jsonDecode(res.body);
    } on TimeoutException {
      throw Exception('Connection timeout — Backend รันอยู่ไหม? $baseUrl');
    } on SocketException catch (e) {
      throw Exception('เชื่อมต่อไม่ได้: ${e.message}');
    }
  }

  // ─── Docker ───────────────────────────────────────────
  static Future<List> getDockerImages() async {
    final res = await get('/firebase/docker-images');
    return res['data'] ?? [];
  }

  static Future<List> getContainers() async {
    final res = await get('/docker/containers');
    return res['data'] ?? [];
  }

  static Future<Map> runContainer(
    String image, {
    String? name,
    int port = 80,
  }) async {
    final ports = {
      '$port/tcp': [
        {'HostPort': '${8080 + DateTime.now().millisecond % 1000}'},
      ],
    };
    return await post('/docker/run', {
      'image': image,
      if (name != null) 'name': name,
      'ports': ports,
    });
  }

  static Future<Map> stopContainer(String containerId) async {
    return await post('/docker/stop', {'containerId': containerId});
  }

  static Future<String> getContainerLogs(String containerId) async {
    final res = await get('/docker/containers/$containerId/logs');
    return res['data'] ?? '';
  }

  // ─── Kubernetes ───────────────────────────────────────
  static Future<List> getPods() async {
    final res = await get('/k8s/pods');
    return res['data'] ?? [];
  }

  static Future<List> getNodes() async {
    final res = await get('/k8s/nodes');
    return res['data'] ?? [];
  }

  static Future<List> getDeployments() async {
    final res = await get('/k8s/deployments');
    return res['data'] ?? [];
  }

  static Future<List> getServices() async {
    final res = await get('/k8s/services');
    return res['data'] ?? [];
  }

  static Future<Map> deployApp(
    String name,
    String image,
    int replicas,
    int port, {
    String slot = 'blue',
  }) async {
    return await post('/k8s/deploy', {
      'name': name,
      'image': image,
      'replicas': replicas,
      'port': port,
      'slot': slot,
    });
  }

  static Future<Map> scaleDeployment(String name, int replicas) async {
    return await post('/k8s/scale', {'name': name, 'replicas': replicas});
  }

  static Future<Map> deletePod(String name) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl/k8s/pods/$name'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body);
  }

  static Future<Map> deleteDeployment(String name) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl/k8s/deployments/$name'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body);
  }

  static Future<Map> deleteService(String name) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl/k8s/services/$name'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body);
  }

  static Future<Map> restartDeployment(String name) async {
    return await post('/k8s/deployments/$name/restart', {});
  }

  // ─── CI/CD Pipeline ───────────────────────────────────
  static Future<Map> triggerPipeline({String jobName = 'devops-lab'}) async {
    return await post('/pipeline/start', {'jobName': jobName});
  }

  static Future<Map> getPipelineStatus(String jobName) async {
    return await get('/pipeline/status/$jobName');
  }

  static Future<String> getPipelineLogs(String jobName) async {
    final res = await get('/pipeline/logs/$jobName');
    return res['data'] ?? '';
  }

  static Future<List> getPipelineStages(String jobName) async {
    final res = await get('/pipeline/stages/$jobName');
    return res['data'] ?? [];
  }

  // ─── Monitoring ───────────────────────────────────────
  static Future<Map<String, dynamic>> getClusterMetrics() async {
    final res = await get('/monitoring/cluster');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  static Future<List<dynamic>> getPodMetrics() async {
    final res = await get('/monitoring/pods');
    return List<dynamic>.from(res['data'] as List? ?? []);
  }

  // ─── Blue-Green ───────────────────────────────────────
  static Future<Map> getBlueGreenStatus() async {
    final res = await get('/bluegreen/status');
    return res['data'] ?? {};
  }

  static Future<Map> switchTraffic(String targetSlot) async {
    return await post('/bluegreen/switch', {'targetSlot': targetSlot});
  }

  static Future<Map> rollback() async {
    return await post('/bluegreen/rollback', {});
  }
}
