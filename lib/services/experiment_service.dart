import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/experiment_session.dart';
import '../models/input_reading.dart';
import '../models/output_reading.dart';
import 'neon_http_service.dart';
import 'user_identity.dart';

/// Database and in-memory state service for managing Experiment 5 data.
class ExperimentService {
  // Shared in-memory data store across all screens
  static List<InputReading> liveInputReadings = _generateDefaultInputReadings();
  static List<OutputReading> liveOutputReadings = _generateDefaultOutputReadings();

  static List<InputReading> _generateDefaultInputReadings() {
    final list = <InputReading>[];
    final steps = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    for (final vbb in steps) {
      double vbe = 0.0, ib = 0.0;
      if (vbb > 0.6) {
        vbe = 0.65 + (vbb / 5.0) * 0.07;
        ib = (vbb - vbe) / 1.0 * 1000.0;
      }
      list.add(InputReading(
        vbb: vbb,
        vce: 1.0,
        vbe: double.parse(vbe.toStringAsFixed(3)),
        ib: double.parse(ib.toStringAsFixed(1)),
      ));
      list.add(InputReading(
        vbb: vbb,
        vce: 2.0,
        vbe: double.parse(vbe.toStringAsFixed(3)),
        ib: double.parse((ib * 0.98).toStringAsFixed(1)),
      ));
    }
    return list;
  }

  static List<OutputReading> _generateDefaultOutputReadings() {
    final list = <OutputReading>[];
    final steps = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
    for (final vcc in steps) {
      double vce = vcc * 0.9, ic = 0.65;
      if (vcc <= 1.0) {
        vce = vcc * 0.2;
        ic = vcc * 0.6;
      }
      list.add(OutputReading(
        vcc: vcc,
        ib: 4.3,
        vce: double.parse(vce.toStringAsFixed(2)),
        ic: double.parse(ic.toStringAsFixed(2)),
      ));
    }
    for (final vcc in steps) {
      double vce = vcc * 0.85, ic = 1.50;
      if (vcc <= 1.0) {
        vce = vcc * 0.25;
        ic = vcc * 1.4;
      }
      list.add(OutputReading(
        vcc: vcc,
        ib: 10.0,
        vce: double.parse(vce.toStringAsFixed(2)),
        ic: double.parse(ic.toStringAsFixed(2)),
      ));
    }
    return list;
  }

  /// Saves an experiment session containing raw input and output readings to cloud database.
  static Future<ExperimentSession> saveExperimentSession({
    List<InputReading>? inputReadings,
    List<OutputReading>? outputReadings,
  }) async {
    final inputsToSave = inputReadings ?? liveInputReadings;
    final outputsToSave = outputReadings ?? liveOutputReadings;

    final userId = await getOrCreateUserId();
    final sessionId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final inputJson = jsonEncode(inputsToSave.map((r) => r.toJson()).toList());
    final outputJson = jsonEncode(outputsToSave.map((r) => r.toJson()).toList());

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
      inputReadings: inputsToSave,
      outputReadings: outputsToSave,
    );
  }

  /// Retrieves all experiment sessions for the current device from cloud database.
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
    if (sessions.isNotEmpty) {
      final s = sessions.first;
      if (s.inputReadings.isNotEmpty) {
        liveInputReadings = List.from(s.inputReadings);
      }
      if (s.outputReadings.isNotEmpty) {
        liveOutputReadings = List.from(s.outputReadings);
      }
      return s;
    }
    return null;
  }
}
