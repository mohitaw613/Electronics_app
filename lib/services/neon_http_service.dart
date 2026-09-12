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
  // Use [params] for parameterized queries (e.g. WHERE id = $1) to prevent
  // SQL injection. Throws an Exception if Neon returns an error.
  static Future<Map<String, dynamic>> execute(
    String query, {
    List<dynamic> params = const [],
  }) async {
    final response = await http.post(
      _sqlEndpoint,
      headers: {
        'Content-Type': 'application/json',
        // Neon-Connection-String authenticates the request and routes it
        // to the correct database and user.
        'Neon-Connection-String': DbConfig.connectionString,
      },
      body: jsonEncode({
        'query': query,
        // Only include params key if there are actual parameters.
        if (params.isNotEmpty) 'params': params,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Neon sends errors as {"message": "error text"} — convert to exception.
    if (json.containsKey('message')) {
      throw Exception('Neon error: ${json['message']}');
    }

    return json;
  }

  // Lightweight connection check — sends SELECT 1 to verify Neon is reachable.
  // Returns true on success, false on any failure (no internet, wrong creds, etc).
  static Future<bool> ping() async {
    try {
      await execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }
}
