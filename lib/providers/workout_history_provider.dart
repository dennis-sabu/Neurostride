import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_provider.dart';

class WorkoutHistoryNotifier extends Notifier<List<WorkoutHistoryEntry>> {
  static const _key = 'saved_workouts';

  @override
  List<WorkoutHistoryEntry> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final entries = decoded
            .map((e) => WorkoutHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort newest first
        entries.sort((a, b) => b.endTime.compareTo(a.endTime));

        state = entries;
      } catch (e) {
        // Handle misformatted data
        state = [];
      }
    }
  }

  Future<void> addEntry(WorkoutHistoryEntry entry) async {
    final updated = [entry, ...state]; // Insert at start
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}

final workoutHistoryProvider =
    NotifierProvider<WorkoutHistoryNotifier, List<WorkoutHistoryEntry>>(
      WorkoutHistoryNotifier.new,
    );
