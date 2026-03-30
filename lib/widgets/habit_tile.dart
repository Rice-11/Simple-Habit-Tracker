import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../screens/habit_detail_screen.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final DateTime date;

  const HabitTile({super.key, required this.habit, required this.date});

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile>
    with SingleTickerProviderStateMixin {
  static const double _kDeleteWidth = 88.0;
  static const double _kTileHeight = 72.0;

  double _offsetX = 0.0;
  bool _deleteRevealed = false;

  late AnimationController _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.habit.isCompleted(widget.date) ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(HabitTile old) {
    super.didUpdateWidget(old);
    final wasDone = old.habit.isCompleted(old.date);
    final isDone = widget.habit.isCompleted(widget.date);
    if (isDone != wasDone) {
      isDone ? _fillAnim.forward() : _fillAnim.reverse();
    }
  }

  @override
  void dispose() {
    _fillAnim.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_deleteRevealed) {
      _closeDelete();
      return;
    }
    if (!widget.habit.isCompleted(widget.date)) {
      HapticFeedback.lightImpact();
    }
    context.read<HabitService>().toggle(widget.habit.id, widget.date);
  }

  void _closeDelete() {
    setState(() {
      _offsetX = 0;
      _deleteRevealed = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final dx = d.delta.dx;
    if (_deleteRevealed) {
      // Allow closing by dragging right
      setState(() {
        _offsetX = (_offsetX + dx).clamp(-_kDeleteWidth, 0.0);
        if (_offsetX >= -1) {
          _deleteRevealed = false;
          _offsetX = 0;
        }
      });
    } else if (dx < 0) {
      // Swipe left to reveal delete
      setState(() {
        _offsetX = (_offsetX + dx).clamp(-_kDeleteWidth, 0.0);
      });
    }
    // Right swipe handled via velocity in onDragEnd
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;

    if (!_deleteRevealed && vx > 350) {
      // Fast right swipe → navigate to detail
      _navigateToDetail();
      return;
    }

    if (_offsetX < -_kDeleteWidth / 2 || vx < -600) {
      setState(() {
        _offsetX = -_kDeleteWidth;
        _deleteRevealed = true;
      });
    } else {
      setState(() {
        _offsetX = 0;
        _deleteRevealed = false;
      });
    }
  }

  void _navigateToDetail() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => HabitDetailScreen(habitId: widget.habit.id),
      ),
    );
  }

  void _delete() {
    context.read<HabitService>().delete(widget.habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final isRestTomorrow = widget.habit.isRestTomorrow(widget.date);
    final hasFreq = widget.habit.hasFrequency;
    final habitStats = widget.habit.stats(widget.date);
    // Only show % once there are at least 2 trackable days
    final pct = habitStats.totalActive >= 2
        ? '${habitStats.consistencyPercent}%'
        : null;

    return SizedBox(
      height: _kTileHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Delete button (behind tile)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _delete,
                  child: Container(
                    width: _kDeleteWidth,
                    color: CupertinoColors.destructiveRed,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main tile (slides over delete button)
            Transform.translate(
              offset: Offset(_offsetX, 0),
              child: AnimatedBuilder(
                animation: _fillAnim,
                builder: (_, child) {
                  final t = _fillAnim.value;
                  final bg = Color.lerp(
                    CupertinoColors.white,
                    CupertinoColors.black,
                    t,
                  )!;
                  final fg = Color.lerp(
                    CupertinoColors.black,
                    CupertinoColors.white,
                    t,
                  )!;
                  final sub = Color.lerp(
                    const Color(0xFF8E8E93),
                    const Color(0xFFAEAEB2),
                    t,
                  )!;
                  final divider = Color.lerp(
                    const Color(0xFFE5E5EA),
                    const Color(0xFF3A3A3C),
                    t,
                  )!;

                  return Container(
                    width: double.infinity,
                    color: bg,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.habit.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: fg,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                if (isRestTomorrow ||
                                    hasFreq ||
                                    pct != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (isRestTomorrow)
                                        'Rest tomorrow'
                                      else if (hasFreq)
                                        '${widget.habit.activeDays}d on · ${widget.habit.restDays}d rest',
                                      ?pct,
                                    ].join('  ·  '),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: sub,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Bottom separator
                        Container(height: 0.5, color: divider),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
