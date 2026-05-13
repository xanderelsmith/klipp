import 'dart:async';
import 'package:flutter/material.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';

class RecorderController extends ChangeNotifier {
  final DesktopScreenRecorder recorder;
  final String outputDir;
  final VoidCallback onRecordingSaved;
  final VoidCallback onSelectRegion;

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _lastSavedFile;
  String _selectedFormat = 'mkv';
  String _recordingMode = 'Fullscreen';
  Rect? _recordingRegion;

  RecorderController({
    required this.recorder,
    required this.outputDir,
    required this.onRecordingSaved,
    required this.onSelectRegion,
  });

  bool get isRecording => _isRecording;
  int get recordDuration => _recordDuration;
  String? get lastSavedFile => _lastSavedFile;
  String get selectedFormat => _selectedFormat;
  String get recordingMode => _recordingMode;
  Rect? get recordingRegion => _recordingRegion;

  set selectedFormat(String format) {
    _selectedFormat = format;
    notifyListeners();
  }

  set recordingMode(String mode) {
    _recordingMode = mode;
    notifyListeners();
  }

  set recordingRegion(Rect? region) {
    _recordingRegion = region;
    notifyListeners();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordDuration++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      _isRecording = false;
      _stopTimer();
      notifyListeners();
      try {
        final path = await recorder.stopRecording();
        _lastSavedFile = path;
        onRecordingSaved();
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    } else {
      _isRecording = true;
      _lastSavedFile = null;
      _startTimer();
      notifyListeners();
      try {
        await recorder.startRecording(
          format: _selectedFormat,
          x: _recordingRegion?.left.toInt(),
          y: _recordingRegion?.top.toInt(),
          width: _recordingRegion?.width.toInt(),
          height: _recordingRegion?.height.toInt(),
        );
      } catch (e) {
        _isRecording = false;
        _stopTimer();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> selectRecordingArea(BuildContext context) async {
    final TextEditingController xController =
        TextEditingController(text: '${_recordingRegion?.left.toInt() ?? 0}');
    final TextEditingController yController =
        TextEditingController(text: '${_recordingRegion?.top.toInt() ?? 0}');
    final TextEditingController wController = TextEditingController(
      text: '${_recordingRegion?.width.toInt() ?? 1280}',
    );
    final TextEditingController hController = TextEditingController(
      text: '${_recordingRegion?.height.toInt() ?? 720}',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Recording Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: xController,
                    decoration: const InputDecoration(labelText: 'X Offset'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: yController,
                    decoration: const InputDecoration(labelText: 'Y Offset'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: wController,
                    decoration: const InputDecoration(labelText: 'Width'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: hController,
                    decoration: const InputDecoration(labelText: 'Height'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Set Area'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _recordingMode = 'Rectangle';
      _recordingRegion = Rect.fromLTWH(
        double.tryParse(xController.text) ?? 0,
        double.tryParse(yController.text) ?? 0,
        double.tryParse(wController.text) ?? 1280,
        double.tryParse(hController.text) ?? 720,
      );
      notifyListeners();
    }
  }

  void startRegionSelection() {
    onSelectRegion();
  }

  String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
