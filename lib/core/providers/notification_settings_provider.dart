import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationSettingsNotifier(prefs);
});

class NotificationSettingsNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'flood_notification_enabled';

  NotificationSettingsNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);

  Future<void> toggle() async {
    final newValue = !state;
    await _prefs.setBool(_key, newValue);
    state = newValue;
  }
}
