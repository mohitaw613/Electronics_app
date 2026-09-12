import 'input_reading.dart';
import 'output_reading.dart';

/// Model representing a full Experiment 5 session saved in Neon PostgreSQL.
class ExperimentSession {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final List<InputReading> inputReadings;
  final List<OutputReading> outputReadings;

  const ExperimentSession({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    this.inputReadings = const [],
    this.outputReadings = const [],
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        'input_readings': inputReadings.map((r) => r.toJson()).toList(),
        'output_readings': outputReadings.map((r) => r.toJson()).toList(),
      };

  factory ExperimentSession.fromJson(Map<String, dynamic> json) =>
      ExperimentSession(
        sessionId: json['session_id'] as String,
        userId: json['user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        inputReadings: (json['input_readings'] as List<dynamic>?)
                ?.map((e) => InputReading.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        outputReadings: (json['output_readings'] as List<dynamic>?)
                ?.map((e) => OutputReading.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
