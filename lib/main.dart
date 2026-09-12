import 'package:flutter/material.dart';
import 'services/user_identity.dart';
import 'services/neon_http_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electronics App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'BJT Common Emitter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Represents the 3 possible states of the Neon PostgreSQL connection.
enum DbStatus { checking, connected, failed }

class _MyHomePageState extends State<MyHomePage> {
  // Tracks current database connection status.
  DbStatus _dbStatus = DbStatus.checking;

  // Stores error message when connection fails.
  String _dbError = '';

  @override
  void initState() {
    super.initState();
    // On app open: check connection and save device to database.
    _checkDbConnection();
    _saveDeviceUser();
  }

  /// Pings Neon PostgreSQL via HTTPS (port 443).
  /// Works on all networks including college Wi-Fi where port 5432 is blocked.
  Future<void> _checkDbConnection() async {
    setState(() {
      _dbStatus = DbStatus.checking;
      _dbError = '';
    });
    try {
      final isAlive = await NeonHttpService.ping();
      if (isAlive) {
        setState(() => _dbStatus = DbStatus.connected);
        print('DB Connection: SUCCESS (port 443)');
      } else {
        setState(() {
          _dbStatus = DbStatus.failed;
          _dbError = 'No response from Neon HTTP API';
        });
        print('DB Connection: FAILED — No response');
      }
    } catch (e) {
      setState(() {
        _dbStatus = DbStatus.failed;
        _dbError = e.toString();
      });
      print('DB Connection: FAILED — $e');
    }
  }

  /// Stores this device's unique UUID and timestamp into the Neon
  /// [device_users] table. ON CONFLICT DO NOTHING ensures existing
  /// data is never overwritten or deleted on repeat app opens.
  Future<void> _saveDeviceUser() async {
    try {
      final userId = await getOrCreateUserId();
      await NeonHttpService.execute(
        'INSERT INTO device_users (user_id, created_at) '
        'VALUES (\$1, NOW()) '
        'ON CONFLICT (user_id) DO NOTHING',
        params: [userId],
      );
      print('Device user saved: $userId');
    } catch (e) {
      print('Failed to save device user: $e');
    }
  }

  /// Builds the DB connection status card at the top of the screen.
  Widget _buildStatusCard() {
    Color cardColor;
    Color textColor;
    IconData icon;
    String message;

    switch (_dbStatus) {
      case DbStatus.checking:
        cardColor = Colors.amber.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        message = 'Checking Neon PostgreSQL connection...';
        break;
      case DbStatus.connected:
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        message = 'Neon PostgreSQL Connected ✓';
        break;
      case DbStatus.failed:
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        message = 'Connection Failed: $_dbError';
        break;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _dbStatus == DbStatus.checking
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            // Retry button only appears when connection fails.
            if (_dbStatus == DbStatus.failed)
              TextButton(
                onPressed: _checkDbConnection,
                child: Text('Retry', style: TextStyle(color: textColor)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // DB connection status card — always visible at the top.
          _buildStatusCard(),
          const Expanded(
            child: Center(
              child: Text(
                'BJT Common Emitter App',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
