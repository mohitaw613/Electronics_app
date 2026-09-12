import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/experiment_session.dart';
import '../models/input_reading.dart';
import '../models/output_reading.dart';
import 'neon_http_service.dart';
import 'user_identity.dart';

/// Database service for managing Experiment 5 sessions in Neon PostgreSQL.
/// (Module assigned to Mohit).
class ExperimentService {
  /// Saves a new experiment session containing raw input and output readings to Neon.
  static Future<ExperimentSession> saveExperimentSession({
    List<InputReading> inputReadings = const [],
    List<OutputReading> outputReadings = const [],
  }) async {
    final userId = await getOrCreateUserId();
    final sessionId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final inputJson = jsonEncode(inputReadings.map((r) => r.toJson()).toList());
    final outputJson = jsonEncode(outputReadings.map((r) => r.toJson()).toList());

    await NeonHttpService.execute(
      'INSERT INTO experiment_sessions (session_id, user_id, created_at, input_readings, output_readings) '
      'VALUES (\$1, \$2, \$3, \$4::jsonb, \$5::jsonb)',
      params: [
        sessionId,
        userId,
        now.toIso8601String(),
        inputJson,
        outputJson,
      ],
    );

    return ExperimentSession(
      sessionId: sessionId,
      userId: userId,
      createdAt: now,
      inputReadings: inputReadings,
      outputReadings: outputReadings,
    );
  }

  /// Retrieves all experiment sessions for the current device from Neon.
  static Future<List<ExperimentSession>> getExperimentSessions() async {
    final userId = await getOrCreateUserId();

    final result = await NeonHttpService.execute(
      'SELECT session_id, user_id, created_at, input_readings, output_readings '
      'FROM experiment_sessions '
      'WHERE user_id = \$1 '
      'ORDER BY created_at DESC',
      params: [userId],
    );

    final rows = result['rows'] as List<dynamic>? ?? [];

    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final rawInput = map['input_readings'];
      final rawOutput = map['output_readings'];

      List<InputReading> inputs = [];
      if (rawInput is List) {
        inputs = rawInput.map((e) => InputReading.fromJson(e as Map<String, dynamic>)).toList();
      } else if (rawInput is String) {
        final decoded = jsonDecode(rawInput) as List;
        inputs = decoded.map((e) => InputReading.fromJson(e as Map<String, dynamic>)).toList();
      }

      List<OutputReading> outputs = [];
      if (rawOutput is List) {
        outputs = rawOutput.map((e) => OutputReading.fromJson(e as Map<String, dynamic>)).toList();
      } else if (rawOutput is String) {
        final decoded = jsonDecode(rawOutput) as List;
        outputs = decoded.map((e) => OutputReading.fromJson(e as Map<String, dynamic>)).toList();
      }

      return ExperimentSession(
        sessionId: map['session_id'] as String,
        userId: map['user_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        inputReadings: inputs,
        outputReadings: outputs,
      );
    }).toList();
  }

  /// Retrieves the most recent experiment session for graphing.
  static Future<ExperimentSession?> getLatestSession() async {
    final sessions = await getExperimentSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }
}
