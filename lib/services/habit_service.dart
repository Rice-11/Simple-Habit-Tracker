import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'notification_service.dart';

class HabitService extends ChangeNotifier {
  static const _key = 'habits_v1';
  List<Habit> _habits = [];

  List<Habit> get all => List.unmodifiable(_habits);

  List<Habit> visibleOn(DateTime date) =>
      _habits.where((h) => !h.isRestDay(date)).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _habits = list
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> add(Habit habit) async {
    _habits.add(habit);
    await _save();
    await NotificationService.schedule(habit);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _habits.removeWhere((h) => h.id == id);
    await NotificationService.cancel(id);
    await _save();
    notifyListeners();
  }

  Future<void> toggle(String id, DateTime date) async {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i < 0) return;
    _habits[i] = _habits[i].withCompletion(date, !_habits[i].isCompleted(date));
    await _save();
    notifyListeners();
  }

  Future<void> update(Habit habit) async {
    final i = _habits.indexWhere((h) => h.id == habit.id);
    if (i < 0) return;
    _habits[i] = habit;
    await NotificationService.schedule(habit);
    await _save();
    notifyListeners();
  }

  /// Reorders based on the currently visible list (handles rest-day gaps).
  Future<void> reorderVisible(
    int oldIndex,
    int newIndex,
    List<Habit> visible,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;

    // Build the new visible order
    final newVisible = List<Habit>.from(visible);
    final moved = newVisible.removeAt(oldIndex);
    newVisible.insert(newIndex, moved);

    // Slot the reordered visible habits back into _habits,
    // leaving non-visible (rest-day) habits in their original positions.
    final visibleIds = visible.map((h) => h.id).toSet();
    int vIdx = 0;
    _habits = _habits.map((h) {
      if (visibleIds.contains(h.id)) return newVisible[vIdx++];
      return h;
    }).toList();

    await _save();
    notifyListeners();
  }
}
