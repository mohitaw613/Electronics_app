import 'package:flutter/material.dart';
import 'services/user_identity.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final success = await AuthService.signUp(
    email: 'codersyoui613@gmail.com',
    password: 'xyer45@Test',
    name: 'Test User',
  );

  print('SIGN UP SUCCESS: $success');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in
  // this case the title) provided by the parent (in this case the App widget)
  // and is used by the build method of the State. Fields in a Widget subclass
  // are always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Enum representing the 3 possible states of the database connection.
enum DbStatus { checking, connected, failed }

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // Tracks the current database connection status.
  DbStatus _dbStatus = DbStatus.checking;

  // Stores the error message if the connection fails.
  String _dbError = '';

  @override
  void initState() {
    super.initState();
    // Automatically check the Neon PostgreSQL connection when the screen loads.
    _checkDbConnection();
  }

  /// Attempts to open a connection to Neon PostgreSQL, runs a lightweight
  /// SELECT 1 ping query, then closes the connection cleanly.
  /// Updates [_dbStatus] to reflect the result.
  Future<void> _checkDbConnection() async {
    setState(() {
      _dbStatus = DbStatus.checking;
      _dbError = '';
    });
    try {
      final connection = await DatabaseService.connect();
      await connection.execute('SELECT 1');
      await connection.close();
      setState(() => _dbStatus = DbStatus.connected);
      print('DB Connection: SUCCESS');
    } catch (e) {
      setState(() {
        _dbStatus = DbStatus.failed;
        _dbError = e.toString();
      });
      print('DB Connection: FAILED — $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  /// Builds the connection status card shown at the top of the screen.
  /// Color and icon change based on [_dbStatus].
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
            // Spinner for checking state, icon for connected/failed.
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
            // Retry button shown only when the connection has failed.
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Database connection status card at the top of the screen.
          _buildStatusCard(),
          Expanded(
            child: Center(
              // Center is a layout widget. It takes a single child and
              // positions it in the middle of the parent.
              child: Column(
                // Column is also a layout widget. It takes a list of children
                // and arranges them vertically. By default, it sizes itself to
                // fit its children horizontally, and tries to be as tall as
                // its parent.
                //
                // Column has various properties to control how it sizes itself
                // and how it positions its children. Here we use
                // mainAxisAlignment to center the children vertically; the
                // main axis here is the vertical axis because Columns are
                // vertical (the cross axis would be horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug
                // Paint" action in the IDE, or press "p" in the console), to
                // see the wireframe for each widget.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You have pushed the button this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
