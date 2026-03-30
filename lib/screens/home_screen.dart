import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show ReorderableDelayedDragStartListener, ReorderableListView;
import 'package:provider/provider.dart';
import '../services/habit_service.dart';
import '../widgets/habit_tile.dart';
import '../widgets/add_habit_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _todayLabel(DateTime date) {
    const weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Habits',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: CupertinoColors.black,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => _showAddSheet(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Icon(
              CupertinoIcons.add,
              size: 26,
              color: CupertinoColors.black,
            ),
          ),
        ),
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Consumer<HabitService>(
          builder: (context, service, _) {
            final habits = service.visibleOn(today);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Text(
                    _todayLabel(today),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: habits.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No habits today',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap + to add your first habit',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: habits.length,
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            service.reorderVisible(oldIndex, newIndex, habits);
                          },
                          itemBuilder: (context, i) =>
                              ReorderableDelayedDragStartListener(
                                key: ValueKey(habits[i].id),
                                index: i,
                                child: HabitTile(habit: habits[i], date: today),
                              ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const AddHabitSheet(),
    );
  }
}
