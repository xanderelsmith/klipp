import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/styles/app_styles.dart';
import 'app/recorder_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Guarantee mouse events are enabled on launch
    await windowManager.setIgnoreMouseEvents(false);
  });

  runApp(const KlippApp());
}

class KlippApp extends StatelessWidget {
  const KlippApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klipp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        useMaterial3: true,
      ),
      home: const RecorderDashboard(),
    );
  }
}
