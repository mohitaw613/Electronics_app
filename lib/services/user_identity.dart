import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getOrCreateUserId() async {
  final prefs = SharedPreferencesAsync();

  const key = 'user_id';

  final existingId = await prefs.getString(key);

  if (existingId != null && existingId.isNotEmpty) {
    return existingId;
  }

  final newId = const Uuid().v4();

  await prefs.setString(key, newId);

  return newId;
}
