import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habits/main.dart';
import 'package:habits/services/habit_service.dart';

void main() {
  testWidgets('renders home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitService(),
        child: const HabitsApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Habits'), findsOneWidget);
  });
}
