import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_config.dart';

/// A service that communicates with Neon PostgreSQL over HTTPS (port 443)
/// using Neon's built-in HTTP SQL API.
///
/// Unlike [DatabaseService] which uses the PostgreSQL TCP wire protocol
/// on port 5432 (often blocked on college/enterprise Wi-Fi), this service
/// sends SQL queries as standard HTTP POST requests on port 443, which is
/// never blocked on any network.
class NeonHttpService {
  /// The Neon HTTP SQL API endpoint. Neon exposes this on every project host.
  static final Uri _sqlEndpoint =
      Uri.parse('https://${DbConfig.host}/sql');

  /// Executes a raw SQL query via the Neon HTTP API.
  ///
  /// Returns the parsed JSON response body as a [Map].
  /// Throws an [Exception] if the HTTP request fails or Neon returns an error.
  static Future<Map<String, dynamic>> execute(String query,
      {List<dynamic> params = const []}) async {
    final response = await http.post(
      _sqlEndpoint,
      headers: {
        'Content-Type': 'application/json',
        // The Neon-Connection-String header authenticates the request and
        // tells Neon which database and user to connect as.
        'Neon-Connection-String': DbConfig.connectionString,
      },
      body: jsonEncode({
        'query': query,
        if (params.isNotEmpty) 'params': params,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Neon returns an error object with a "message" key when something fails.
    if (json.containsKey('message')) {
      throw Exception('Neon API error: ${json['message']}');
    }

    return json;
  }

  /// Sends a lightweight SELECT 1 query to verify the database is reachable.
  ///
  /// Returns [true] if Neon responds successfully, [false] otherwise.
  /// This is used by the connection status card in [main.dart].
  static Future<bool> ping() async {
    try {
      await execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }
}
