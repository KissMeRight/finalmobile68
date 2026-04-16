import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/docker_screen.dart';
import 'screens/kubernetes_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/pipeline_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyDevOpsApp());
}

class MyDevOpsApp extends StatelessWidget {
  const MyDevOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevOps Lap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DockerScreen(),
    const KubernetesScreen(),
    const MonitoringScreen(),
    const PipelineScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF30363D))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Docker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hub_outlined),
              activeIcon: Icon(Icons.hub),
              label: 'K8s',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: 'CI/CD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Monitor',
            ),
          ],
        ),
      ),
    );
  }
}
