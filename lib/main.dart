import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';

import 'core/styles/app_styles.dart';
import 'core/utils/logger.dart';

import 'features/recorder/presentation/controllers/recorder_controller.dart';
import 'features/recorder/presentation/pages/recorder_page.dart';
import 'features/recorder/presentation/pages/region_selector_page.dart';
import 'features/recorder/presentation/widgets/sidebar.dart';
import 'features/recorder/presentation/widgets/top_bar.dart';

import 'features/converter/presentation/controllers/converter_controller.dart';
import 'features/converter/presentation/pages/converter_page.dart';

import 'features/gallery/presentation/controllers/gallery_controller.dart';
import 'features/gallery/presentation/pages/gallery_page.dart';

import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/settings/presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
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

class RecorderDashboard extends StatefulWidget {
  const RecorderDashboard({super.key});

  @override
  State<RecorderDashboard> createState() => _RecorderDashboardState();
}

class _RecorderDashboardState extends State<RecorderDashboard> {
  final _recorder = DesktopScreenRecorder();
  String _outputDir = 'Loading...';
  int _selectedIndex = 0;
  bool _isSelectingRegion = false;
  Rect? _initialRegion;

  late RecorderController _recorderController;
  late ConverterController _converterController;
  late GalleryController _galleryController;
  late SettingsController _settingsController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final klippDir = Directory('${directory.path}\\klippvideos');
      if (!await klippDir.exists()) {
        await klippDir.create(recursive: true);
      }

      setState(() {
        _outputDir = klippDir.path;
        _galleryController = GalleryController(outputDir: _outputDir);
        _recorderController = RecorderController(
          recorder: _recorder,
          outputDir: _outputDir,
          onRecordingSaved: () => _galleryController.loadFiles(),
          onSelectRegion: (rect) => _enterSelectionMode(rect),
        );
        _converterController = ConverterController(
          recorder: _recorder,
          outputDir: _outputDir,
          onConversionCompleted: () => _galleryController.loadFiles(),
        );
        _settingsController = SettingsController();
        _isInitialized = true;
      });

      await _galleryController.loadFiles();
      await _settingsController.checkFfmpeg();
      AppLogger.info('App initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('App initialization failed', e, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _recorderController.dispose();
      _converterController.dispose();
      _galleryController.dispose();
      _settingsController.dispose();
    }
    super.dispose();
  }

  Future<void> _enterSelectionMode(Rect? initial) async {
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    setState(() {
      _initialRegion = initial;
      _isSelectingRegion = true;
    });
  }

  Future<void> _exitSelectionMode() async {
    // Always re-enable mouse events when returning to the dashboard
    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);
    await windowManager.setSize(const Size(1280, 720));
    await windowManager.center();
    setState(() => _isSelectingRegion = false);
  }

  Future<void> _openOutputFolder([String? specificFile]) async {
    try {
      final dir = Directory(_outputDir);
      if (!await dir.exists()) return;

      if (specificFile != null) {
        Process.run('explorer.exe', ['/select,', specificFile]);
      } else {
        Process.run('explorer.exe', [_outputDir]);
      }
    } catch (e) {
      AppLogger.error('Could not open folder', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isSelectingRegion ? Colors.transparent : null,
      body: _isSelectingRegion
          ? RegionSelectorPage(
              controller: _recorderController,
              initialRect: _initialRegion,
              onIgnoreMouseEvents: (ignore) async {
                await windowManager.setIgnoreMouseEvents(ignore);
              },
              onRegionSelected: (rect) {
                _recorderController.recordingRegion = rect;
                _recorderController.recordingMode = 'Rectangle';
              },
              onCancel: _exitSelectionMode,
            )
          : Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) =>
                      setState(() => _selectedIndex = index),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TopBar(
                        selectedIndex: _selectedIndex,
                        recorderController: _recorderController,
                      ),
                      Expanded(child: _buildCurrentTab()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return RecorderPage(
          controller: _recorderController,
          galleryController: _galleryController,
          onOpenFolder: _openOutputFolder,
        );
      case 1:
        return ConverterPage(controller: _converterController);
      case 2:
        return GalleryPage(
          controller: _galleryController,
          onOpenFolder: _openOutputFolder,
        );
      case 3:
        return SettingsPage(controller: _settingsController);
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
