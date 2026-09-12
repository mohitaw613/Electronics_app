import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_config.dart';

// Handles all communication with Neon PostgreSQL over HTTPS (port 443).
// Uses Neon's built-in HTTP SQL API instead of a direct TCP connection,
// so it works on all networks — including college Wi-Fi that blocks port 5432.
class NeonHttpService {
  // Neon's HTTP SQL API endpoint — available on every Neon project by default.
  static final Uri _sqlEndpoint =
      Uri.parse('https://${DbConfig.host}/sql');

  // Sends any SQL query to Neon over HTTPS and returns the result as a Map.
  // Enforces a fast 3.5s timeout so UI never lags or hangs when network is slow.
  static Future<Map<String, dynamic>> execute(
    String query, {
    List<dynamic> params = const [],
  }) async {
    final response = await http
        .post(
          _sqlEndpoint,
          headers: {
            'Content-Type': 'application/json',
            'Neon-Connection-String': DbConfig.connectionString,
          },
          body: jsonEncode({
            'query': query,
            if (params.isNotEmpty) 'params': params,
          }),
        )
        .timeout(
          const Duration(milliseconds: 3500),
          onTimeout: () => throw Exception('Network timeout: Neon database not responding'),
        );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Neon sends errors as {"message": "error text"} — convert to exception.
    if (json.containsKey('message')) {
      throw Exception('Neon error: ${json['message']}');
    }

    return json;
  }

  // Lightweight connection check with 2.5s timeout.
  static Future<bool> ping() async {
    try {
      await execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }
}
