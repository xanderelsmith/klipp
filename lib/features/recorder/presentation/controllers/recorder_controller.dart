import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';
import '../../../../core/utils/logger.dart';

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
    AppLogger.info('Recording format changed to: $format');
    notifyListeners();
  }

  set recordingMode(String mode) {
    _recordingMode = mode;
    AppLogger.info('Recording mode changed to: $mode');
    notifyListeners();
  }

  set recordingRegion(Rect? region) {
    _recordingRegion = region;
    AppLogger.info('Recording region updated: $region');
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
      _recordDuration = 0; // Reset immediately
      notifyListeners();
      try {
        final path = await recorder.stopRecording();
        _lastSavedFile = path;
        AppLogger.info('Recording stopped. File saved at: $path');
        onRecordingSaved();
        notifyListeners();
      } catch (e, stackTrace) {
        AppLogger.error('Failed to stop recording', e, stackTrace);
        rethrow;
      }
    } else {
      _isRecording = true;
      _lastSavedFile = null;
      _startTimer();
      notifyListeners();
      try {
        AppLogger.info('Starting recording: Mode=$recordingMode, Format=$selectedFormat');

        // Scale logical pixels to physical pixels for FFmpeg
        final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
        
        int? x, y, width, height;
        if (_recordingRegion != null) {
          x = (_recordingRegion!.left * dpr).round();
          y = (_recordingRegion!.top * dpr).round();
          width = (_recordingRegion!.width * dpr).round();
          height = (_recordingRegion!.height * dpr).round();
          
          // FFmpeg sometimes requires even dimensions
          if (width % 2 != 0) width++;
          if (height % 2 != 0) height++;
        }

        await recorder.startRecording(
          format: _selectedFormat,
          x: x,
          y: y,
          width: width,
          height: height,
        );
      } catch (e, stackTrace) {
        _isRecording = false;
        _stopTimer();
        AppLogger.error('Failed to start recording', e, stackTrace);
        notifyListeners();
        rethrow;
      }
    }
  }

  void startRegionSelection() {
    AppLogger.info('Entering region selection mode');
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
