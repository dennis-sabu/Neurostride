import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    // ✅ Insert new entry at front, cap at 100 to prevent unbounded storage
    final updated = [entry, ...state];
    final capped = updated.length > 100 ? updated.sublist(0, 100) : updated;
    state = capped;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(capped.map((e) => e.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('[WorkoutHistory] Save failed: $e');
    }
  }
}

final workoutHistoryProvider =
    NotifierProvider<WorkoutHistoryNotifier, List<WorkoutHistoryEntry>>(
      WorkoutHistoryNotifier.new,
    );
