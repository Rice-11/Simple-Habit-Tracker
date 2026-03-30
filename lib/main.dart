import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/habit_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final service = HabitService();
  await service.load();
  runApp(
    ChangeNotifierProvider.value(value: service, child: const HabitsApp()),
  );
}

class HabitsApp extends StatelessWidget {
  const HabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Habits',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.black,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          primaryColor: CupertinoColors.black,
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: CupertinoColors.black,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: <Locale>[Locale('en')],
      home: HomeScreen(),
    );
  }
}
