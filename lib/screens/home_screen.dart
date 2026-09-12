import 'package:flutter/material.dart';
import '../services/neon_http_service.dart';
import '../services/user_identity.dart';
import 'input_screen.dart';
import 'output_screen.dart';
import 'graph_screen.dart';
import 'theory_screen.dart';
import 'simulation_screen.dart';

import '../main.dart';

enum DbStatus { checking, connected, failed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DbStatus _dbStatus = DbStatus.checking;
  String _dbError = '';

  @override
  void initState() {
    super.initState();
    _checkDbConnection();
    _saveDeviceUser();
  }

  Future<void> _checkDbConnection() async {
    setState(() {
      _dbStatus = DbStatus.checking;
      _dbError = '';
    });
    try {
      final isAlive = await NeonHttpService.ping();
      if (isAlive) {
        setState(() => _dbStatus = DbStatus.connected);
      } else {
        setState(() {
          _dbStatus = DbStatus.failed;
          _dbError = 'Database unreachable';
        });
      }
    } catch (e) {
      setState(() {
        _dbStatus = DbStatus.failed;
        _dbError = e.toString();
      });
    }
  }

  Future<void> _saveDeviceUser() async {
    try {
      final userId = await getOrCreateUserId();
      await NeonHttpService.execute(
        'INSERT INTO device_users (user_id, created_at) '
        'VALUES (\$1, NOW()) '
        'ON CONFLICT (user_id) DO NOTHING',
        params: [userId],
      );
    } catch (e) {
      // Background device user registration
    }
  }

  Widget _buildStatusBanner() {
    Color cardColor;
    Color textColor;
    IconData icon;
    String message;

    switch (_dbStatus) {
      case DbStatus.checking:
        cardColor = Colors.amber.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        message = 'Connecting to Database...';
        break;
      case DbStatus.connected:
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        message = 'Database Connected ✓';
        break;
      case DbStatus.failed:
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        message = 'Database Offline: $_dbError';
        break;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            if (_dbStatus == DbStatus.failed)
              TextButton(
                onPressed: _checkDbConnection,
                child: Text('Retry', style: TextStyle(color: textColor, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment 5: BJT Common Emitter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  appThemeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildStatusBanner(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'EXPERIMENT MODULES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          _buildNavTile(
            title: 'Input Characteristics',
            subtitle: 'Record IB vs VBE at constant VCE',
            icon: Icons.input,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InputScreen()),
            ),
          ),
          _buildNavTile(
            title: 'Output Characteristics',
            subtitle: 'Record IC vs VCE at constant IB',
            icon: Icons.output,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OutputScreen()),
            ),
          ),
          _buildNavTile(
            title: 'Graph Characteristics',
            subtitle: 'Scientific best-fit curve plotting & scaling',
            icon: Icons.show_chart,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GraphScreen()),
            ),
          ),
          _buildNavTile(
            title: 'Theory & Circuit',
            subtitle: 'Objectives, circuit schematics & pinout',
            icon: Icons.menu_book,
            color: Colors.amber.shade800,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TheoryScreen()),
            ),
          ),
          _buildNavTile(
            title: 'Virtual Simulation',
            subtitle: 'Interactive circuit parameters & current flow',
            icon: Icons.precision_manufacturing,
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimulationScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
