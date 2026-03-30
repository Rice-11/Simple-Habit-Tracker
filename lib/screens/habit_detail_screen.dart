import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late TextEditingController _nameCtrl;
  late FocusNode _nameFocus;
  DateTime _displayMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    final habit = context.read<HabitService>().all.firstWhere(
      (h) => h.id == widget.habitId,
    );
    _nameCtrl = TextEditingController(text: habit.name);
    _nameFocus = FocusNode();
    _nameFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChanged);
    _nameFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_nameFocus.hasFocus) _saveName();
  }

  void _saveName() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final service = context.read<HabitService>();
    final habit = service.all.firstWhere(
      (h) => h.id == widget.habitId,
      orElse: () => throw StateError('not found'),
    );
    if (habit.name != name) service.update(habit.copyWith(name: name));
  }

  String _monthLabel(DateTime d) {
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
    return '${months[d.month - 1]} ${d.year}';
  }

  String _timeLabel(Habit habit) {
    final hour = habit.reminderHour ?? 20;
    final minute = habit.reminderMinute ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    HabitService service,
    Habit habit,
  ) async {
    var selected = DateTime(
      2000,
      1,
      1,
      habit.reminderHour ?? 20,
      habit.reminderMinute ?? 0,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => Container(
        height: 300,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    onPressed: () async {
                      await service.update(
                        habit.copyWith(
                          reminderHour: selected.hour,
                          reminderMinute: selected.minute,
                        ),
                      );
                      if (context.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: const Color(0xFFD1D1D6)),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selected,
                use24hFormat: false,
                onDateTimeChanged: (dateTime) {
                  selected = dateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService>(
      builder: (context, service, _) {
        final idx = service.all.indexWhere((h) => h.id == widget.habitId);
        if (idx < 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        final habit = service.all[idx];
        final today = DateTime.now();
        final habitStats = habit.stats(today);

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              habit.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            backgroundColor: CupertinoColors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
            ),
          ),
          backgroundColor: CupertinoColors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name ──────────────────────────────────────────────
                  const _SectionLabel('NAME'),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      _saveName();
                      _nameFocus.unfocus();
                    },
                  ),

                  const SizedBox(height: 18),
                  const _SectionLabel('SCHEDULE'),
                  const SizedBox(height: 8),
                  _FrequencyEditor(
                    habit: habit,
                    onToggleEnabled: (enabled) async {
                      if (enabled) {
                        await service.update(
                          habit.copyWith(
                            activeDays: habit.activeDays ?? 3,
                            restDays: habit.restDays ?? 1,
                          ),
                        );
                        return;
                      }
                      await service.update(
                        habit.copyWith(clearFrequency: true),
                      );
                    },
                    onActiveDaysChanged: (value) async {
                      await service.update(
                        habit.copyWith(
                          activeDays: value,
                          restDays: habit.restDays ?? 1,
                        ),
                      );
                    },
                    onRestDaysChanged: (value) async {
                      await service.update(
                        habit.copyWith(
                          activeDays: habit.activeDays ?? 3,
                          restDays: value,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  const _SectionLabel('REMINDER'),
                  const SizedBox(height: 8),
                  _ReminderEditor(
                    enabled: habit.hasReminder,
                    timeLabel: _timeLabel(habit),
                    onToggleEnabled: (enabled) async {
                      if (enabled) {
                        await service.update(
                          habit.copyWith(
                            reminderHour: habit.reminderHour ?? 20,
                            reminderMinute: habit.reminderMinute ?? 0,
                          ),
                        );
                        return;
                      }
                      await service.update(habit.copyWith(clearReminder: true));
                    },
                    onPickTime: () =>
                        _pickReminderTime(context, service, habit),
                  ),

                  const SizedBox(height: 24),

                  // ── Overview ──────────────────────────────────────────
                  const _SectionLabel('OVERVIEW'),
                  const SizedBox(height: 10),
                  _StatsCard(stats: habitStats),

                  const SizedBox(height: 28),

                  // ── History ───────────────────────────────────────────
                  const _SectionLabel('HISTORY'),
                  const SizedBox(height: 14),

                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () => setState(() {
                          _displayMonth = DateTime(
                            _displayMonth.year,
                            _displayMonth.month - 1,
                          );
                        }),
                        child: const Icon(
                          CupertinoIcons.chevron_left,
                          color: CupertinoColors.black,
                          size: 18,
                        ),
                      ),
                      Text(
                        _monthLabel(_displayMonth),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed:
                            _displayMonth.year == today.year &&
                                _displayMonth.month == today.month
                            ? null
                            : () => setState(() {
                                _displayMonth = DateTime(
                                  _displayMonth.year,
                                  _displayMonth.month + 1,
                                );
                              }),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color:
                              _displayMonth.year == today.year &&
                                  _displayMonth.month == today.month
                              ? const Color(0xFFD1D1D6)
                              : CupertinoColors.black,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _CalendarView(
                    habit: habit,
                    month: _displayMonth,
                    onToggle: (date) => service.toggle(habit.id, date),
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: const [
                      _LegendItem(
                        dot: _LegendDot(color: CupertinoColors.black),
                        label: 'Done',
                      ),
                      _LegendItem(
                        dot: _LegendDot(
                          color: Color(0xFFF2F2F7),
                          border: Color(0xFFD1D1D6),
                        ),
                        label: 'Rest',
                      ),
                      _LegendItem(dot: _MissedIndicator(), label: 'Missed'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FrequencyEditor extends StatelessWidget {
  final Habit habit;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<int> onActiveDaysChanged;
  final ValueChanged<int> onRestDaysChanged;

  const _FrequencyEditor({
    required this.habit,
    required this.onToggleEnabled,
    required this.onActiveDaysChanged,
    required this.onRestDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = habit.hasFrequency;
    final activeDays = habit.activeDays ?? 3;
    final restDays = habit.restDays ?? 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom frequency',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
              ),
              CupertinoSwitch(
                value: enabled,
                activeTrackColor: CupertinoColors.black,
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Container(height: 0.5, color: const Color(0xFFD1D1D6)),
            const SizedBox(height: 14),
            _NumberStepper(
              label: 'Active days',
              value: activeDays,
              min: 1,
              max: 30,
              onChanged: onActiveDaysChanged,
            ),
            const SizedBox(height: 12),
            _NumberStepper(
              label: 'Rest days',
              value: restDays,
              min: 1,
              max: 14,
              onChanged: onRestDaysChanged,
            ),
            const SizedBox(height: 12),
            Text(
              '${activeDays}d active \u2192 ${restDays}d rest, repeat',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderEditor extends StatelessWidget {
  final bool enabled;
  final String timeLabel;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onPickTime;

  const _ReminderEditor({
    required this.enabled,
    required this.timeLabel,
    required this.onToggleEnabled,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily reminder',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                ),
              ),
              CupertinoSwitch(
                value: enabled,
                activeTrackColor: CupertinoColors.black,
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Container(height: 0.5, color: const Color(0xFFD1D1D6)),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
        ),
        Row(
          children: [
            _StepButton(
              icon: CupertinoIcons.minus,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            _StepButton(
              icon: CupertinoIcons.plus,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? CupertinoColors.black : const Color(0xFFD1D1D6),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 13, color: CupertinoColors.white),
      ),
    );
  }
}

// ─── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final HabitStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big percentage + label
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats.totalActive == 0 ? '--%' : '${stats.consistencyPercent}%',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'consistency',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          _ProgressBar(value: stats.consistency),
          const SizedBox(height: 16),

          // Divider
          Container(height: 0.5, color: const Color(0xFFD1D1D6)),
          const SizedBox(height: 14),

          // Bottom stats row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: stats.currentStreak == 0
                        ? '--'
                        : '${stats.currentStreak}',
                    label: 'day streak',
                  ),
                ),
                Container(width: 0.5, color: const Color(0xFFD1D1D6)),
                Expanded(
                  child: _StatItem(
                    value: '${stats.totalDone}',
                    label: 'completed',
                  ),
                ),
                Container(width: 0.5, color: const Color(0xFFD1D1D6)),
                Expanded(
                  child: _StatItem(
                    value: stats.longestStreak == 0
                        ? '--'
                        : '${stats.longestStreak}',
                    label: 'best streak',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            Container(color: const Color(0xFFD1D1D6)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: CupertinoColors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}

// ─── Calendar ────────────────────────────────────────────────────────────────

class _CalendarView extends StatelessWidget {
  final Habit habit;
  final DateTime month;
  final void Function(DateTime) onToggle;

  const _CalendarView({
    required this.habit,
    required this.month,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // Sun=0

    return Column(
      children: [
        Row(
          children: headers
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final date = DateTime(month.year, month.month, day);
            return _DayCell(habit: habit, date: date, onToggle: onToggle);
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final void Function(DateTime) onToggle;

  const _DayCell({
    required this.habit,
    required this.date,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDay = DateTime(date.year, date.month, date.day);

    final isFuture = cellDay.isAfter(today);
    final isToday = cellDay == today;
    final isBeforeStart = habit.isBeforeStart(date);
    final isRest = habit.isRestDay(date);
    final isDone = habit.isCompleted(date);

    // Missed = past active day that wasn't completed and habit already existed
    final isMissed =
        !isFuture && !isToday && !isRest && !isDone && !isBeforeStart;

    // Not tappable: future, rest, or before habit was created
    final canTap = !isFuture && !isRest && !isBeforeStart;

    Color bgColor;
    Color textColor;
    BoxBorder? border;

    if (isBeforeStart || isFuture) {
      bgColor = CupertinoColors.white;
      textColor = const Color(0xFFD1D1D6);
    } else if (isRest) {
      bgColor = const Color(0xFFF2F2F7);
      textColor = const Color(0xFFC7C7CC);
    } else if (isDone) {
      bgColor = CupertinoColors.black;
      textColor = CupertinoColors.white;
    } else {
      bgColor = CupertinoColors.white;
      textColor = isMissed ? const Color(0xFF8E8E93) : CupertinoColors.black;
    }

    if (isToday && !isDone && !isRest) {
      border = Border.all(color: CupertinoColors.black, width: 1.5);
    }

    return GestureDetector(
      onTap: canTap ? () => onToggle(date) : null,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: border,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ),
            if (isMissed)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend helpers ───────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Widget dot;
  final String label;
  const _LegendItem({required this.dot, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? border;
  const _LegendDot({required this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: border != null ? Border.all(color: border!) : null,
      ),
    );
  }
}

class _MissedIndicator extends StatelessWidget {
  const _MissedIndicator();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFD1D1D6)),
          ),
        ),
        Positioned(
          bottom: 1,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.systemGrey,
        letterSpacing: 0.6,
      ),
    );
  }
}
