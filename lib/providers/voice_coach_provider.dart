import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the voice coach (TTS) is enabled during exercises.
/// Persisted via SharedPreferences so the setting survives app restarts.
class VoiceCoachNotifier extends Notifier<bool> {
  static const _key = 'voice_coach_enabled';

  @override
  bool build() {
    // Load persisted value asynchronously; default to ON
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final voiceCoachProvider = NotifierProvider<VoiceCoachNotifier, bool>(
  VoiceCoachNotifier.new,
);
