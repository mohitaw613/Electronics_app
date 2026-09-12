import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Returns a unique ID for this device.
// On first app open: generates a new UUID v4 and saves it to phone storage.
// On every open after: reads and returns the same saved UUID.
// This ensures one device always has exactly one permanent identity.
Future<String> getOrCreateUserId() async {
  final prefs = SharedPreferencesAsync();
  const key = 'user_id';

  // Return existing UUID if already saved on this device.
  final existingId = await prefs.getString(key);
  if (existingId != null && existingId.isNotEmpty) {
    return existingId;
  }

  // First open — generate a new UUID, save it, and return it.
  final newId = const Uuid().v4();
  await prefs.setString(key, newId);
  return newId;
}
