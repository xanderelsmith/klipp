import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';

import 'features/recorder/presentation/recorder_controller.dart';
import 'features/recorder/presentation/recorder_page.dart';
import 'features/converter/presentation/converter_controller.dart';
import 'features/converter/presentation/converter_page.dart';
import 'features/gallery/presentation/gallery_controller.dart';
import 'features/gallery/presentation/gallery_page.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/recorder/presentation/region_selector_page.dart';

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
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2D2D2D),
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
        onSelectRegion: _enterSelectionMode,
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

  Future<void> _enterSelectionMode() async {
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    setState(() => _isSelectingRegion = true);
  }

  Future<void> _exitSelectionMode() async {
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
        // On Windows, /select,path opens the folder with the file selected
        Process.run('explorer.exe', ['/select,', specificFile]);
      } else {
        Process.run('explorer.exe', [_outputDir]);
      }
    } catch (e) {
      debugPrint('Could not open folder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: _isSelectingRegion ? Colors.transparent : null,
      body: _isSelectingRegion
          ? RegionSelectorPage(
              controller: _recorderController,
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
                // Sidebar
                _buildSidebar(),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar
                      _buildTopBar(),

                      // Tab Content
                      Expanded(child: _buildCurrentTab()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF252525),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 20),
          _buildNavItem(0, Icons.home, 'Home'),
          _buildNavItem(1, Icons.transform, 'Converter'),
          _buildNavItem(2, Icons.video_library, 'Videos'),
          _buildNavItem(3, Icons.settings, 'Settings'),
          const Spacer(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videocam, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'KLIPP',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Klipp Screen Recorder',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(
            'v1.0.0 Stable',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        color: isSelected ? const Color(0xFF3D3D3D) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.red : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: const Color(0xFF2D2D2D),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListenableBuilder(
        listenable: _recorderController,
        builder: (context, _) {
          return Row(
            children: [
              Icon(Icons.monitor, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text(
                _selectedIndex == 0
                    ? 'Screen Recording Mode - ${_recorderController.recordingMode}'
                    : _selectedIndex == 1
                    ? 'Video Format Converter'
                    : _selectedIndex == 2
                    ? 'Recorded Videos'
                    : 'Settings',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
              ),
              if (_selectedIndex == 0) ...[
                const SizedBox(width: 8),
                _buildModeSelector(),
              ],
              const Spacer(),

              if (_selectedIndex == 0 &&
                  _recorderController.recordingRegion != null) ...[
                Text(
                  '${_recorderController.recordingRegion!.width.toInt()}x${_recorderController.recordingRegion!.height.toInt()} - (${_recorderController.recordingRegion!.left.toInt()}, ${_recorderController.recordingRegion!.top.toInt()})',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontFamily: 'Consolas',
                  ),
                ),
                const SizedBox(width: 16),
              ],

              if (_selectedIndex == 0) ...[
                _buildFormatSelector(),
                const SizedBox(width: 16),
                _buildRecordButton(),
                const SizedBox(width: 16),
                _buildDurationDisplay(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 36,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF4A80D4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.aspect_ratio, color: Colors.white, size: 20),
        offset: const Offset(0, 40),
        tooltip: 'Select Recording Area',
        onSelected: (value) {
          if (value == 'fullscreen') {
            _recorderController.recordingMode = 'Fullscreen';
            _recorderController.recordingRegion = null;
          } else if (value.startsWith('size:')) {
            final parts = value.substring(5).split('x');
            final w = double.parse(parts[0]);
            final h = double.parse(parts[1]);
            _recorderController.recordingMode = 'Rectangle';
            _recorderController.recordingRegion = Rect.fromLTWH(0, 0, w, h);
          } else if (value == 'select_area') {
            _recorderController.startRegionSelection();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'select_area',
            child: ListTile(
              leading: Icon(Icons.crop_free),
              title: Text('Select a recording area'),
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'Rectangle on a screen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 'size:320x240',
            child: Text('320x240 (4:3)'),
          ),
          const PopupMenuItem(
            value: 'size:640x360',
            child: Text('640x360 (16:9)'),
          ),
          const PopupMenuItem(
            value: 'size:1280x720',
            child: Text('1280x720 (16:9)'),
          ),
          const PopupMenuItem(
            value: 'size:1920x1080',
            child: Text('1920x1080 (16:9)'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'fullscreen',
            child: ListTile(
              leading: Icon(Icons.fullscreen),
              title: Text('Fullscreen'),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = ['mkv', 'mp4', 'avi', 'gif'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _recorderController.selectedFormat,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2D2D2D),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
        items: formats
            .map(
              (f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase())),
            )
            .toList(),
        onChanged: _recorderController.isRecording
            ? null
            : (v) => _recorderController.selectedFormat = v!,
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Text(
      _recorderController.formatDuration(_recorderController.recordDuration),
      style: TextStyle(
        color: _recorderController.isRecording ? Colors.red : Colors.grey,
        fontWeight: FontWeight.bold,
        fontFamily: 'Consolas',
      ),
    );
  }

  Widget _buildRecordButton() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1E1E1E),
      ),
      child: IconButton(
        onPressed: () async {
          try {
            await _recorderController.toggleRecording();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recording Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: Icon(
          _recorderController.isRecording
              ? Icons.stop
              : Icons.fiber_manual_record,
          color: Colors.red,
        ),
        tooltip: _recorderController.isRecording
            ? 'Stop Recording'
            : 'Start Recording',
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
