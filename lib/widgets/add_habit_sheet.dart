import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  bool _showOptions = false;
  bool _useFrequency = false;
  int _activeDays = 3;
  int _restDays = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      activeDays: _useFrequency ? _activeDays : null,
      restDays: _useFrequency ? _restDays : null,
      startDate: DateTime.now(),
    );

    context.read<HabitService>().add(habit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'New Habit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameCtrl,
                builder: (context2, value, child) {
                  return CupertinoTextField(
                    controller: _nameCtrl,
                    placeholder: 'Habit name',
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                    placeholderStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFC7C7CC),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Options toggle row
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showOptions = !_showOptions),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showOptions
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Options panel
              if (_showOptions) ...[
                const SizedBox(height: 10),
                _buildFrequencySection(),
              ],

              const SizedBox(height: 20),

              // Add button
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameCtrl,
                  builder: (context2, value, child) {
                    final enabled = value.text.trim().isNotEmpty;
                    return CupertinoButton(
                      color: CupertinoColors.black,
                      disabledColor: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: enabled ? _submit : null,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Text(
                        'Add Habit',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
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
                value: _useFrequency,
                activeTrackColor: CupertinoColors.black,
                onChanged: (v) => setState(() => _useFrequency = v),
              ),
            ],
          ),

          if (_useFrequency) ...[
            const SizedBox(height: 14),
            Container(height: 0.5, color: const Color(0xFFD1D1D6)),
            const SizedBox(height: 14),
            _buildStepper(
              label: 'Active days',
              value: _activeDays,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _activeDays = v),
            ),
            const SizedBox(height: 12),
            _buildStepper(
              label: 'Rest days',
              value: _restDays,
              min: 1,
              max: 14,
              onChanged: (v) => setState(() => _restDays = v),
            ),
            const SizedBox(height: 12),
            Text(
              '${_activeDays}d active → ${_restDays}d rest, repeat',
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

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
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
