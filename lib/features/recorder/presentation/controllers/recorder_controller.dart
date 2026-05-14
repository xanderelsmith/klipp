import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';
import '../../../../core/utils/logger.dart';

class RecorderController extends ChangeNotifier {
  final DesktopScreenRecorder recorder;
  final String outputDir;
  final VoidCallback onRecordingSaved;
  final Function(Rect?) onSelectRegion;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _speakerEnabled = false; // System audio disabled by default
  bool _micEnabled = true; // Mic enabled by default
  double _speakerVolume = 1.0;
  double _micVolume = 1.0;
  String? _selectedSpeakerDevice;
  String? _selectedMicDevice;
  List<String> _availableAudioDevices = [];
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
  }) {
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    _availableAudioDevices = await recorder.listAudioDevices();
    if (_availableAudioDevices.isNotEmpty) {
      _selectedMicDevice ??= _availableAudioDevices.first;
      try {
         _selectedSpeakerDevice ??= _availableAudioDevices.firstWhere((d) => d.toLowerCase().contains('mix') || d.toLowerCase().contains('output'));
      } catch (_) {
         _selectedSpeakerDevice ??= _availableAudioDevices.first;
      }
    }
    notifyListeners();
  }

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get speakerEnabled => _speakerEnabled;
  bool get micEnabled => _micEnabled;
  double get speakerVolume => _speakerVolume;
  double get micVolume => _micVolume;
  String? get selectedSpeakerDevice => _selectedSpeakerDevice;
  String? get selectedMicDevice => _selectedMicDevice;
  List<String> get availableAudioDevices => _availableAudioDevices;

  set speakerEnabled(bool val) {
    _speakerEnabled = val;
    notifyListeners();
  }

  set micEnabled(bool val) {
    _micEnabled = val;
    notifyListeners();
  }

  set speakerVolume(double val) {
    _speakerVolume = val;
    notifyListeners();
  }

  set micVolume(double val) {
    _micVolume = val;
    notifyListeners();
  }

  set selectedSpeakerDevice(String? val) {
    _selectedSpeakerDevice = val;
    notifyListeners();
  }

  set selectedMicDevice(String? val) {
    _selectedMicDevice = val;
    notifyListeners();
  }

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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _recordDuration++;
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      _isRecording = false;
      _isPaused = false;
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
      _isPaused = false;
      _lastSavedFile = null;
      _recordDuration = 0;
      _startTimer();
      notifyListeners();
      try {
        AppLogger.info(
          'Starting recording: Mode=$recordingMode, Format=$selectedFormat',
        );

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

        // Fetch audio devices if needed
        if ((_speakerEnabled || _micEnabled) &&
            _availableAudioDevices.isEmpty) {
          _availableAudioDevices = await recorder.listAudioDevices();
          if (_availableAudioDevices.isNotEmpty) {
            _selectedMicDevice ??= _availableAudioDevices.first;
            // Best effort to auto-select stereo mix or default output for speaker
            try {
              _selectedSpeakerDevice ??= _availableAudioDevices.firstWhere(
                (d) =>
                    d.toLowerCase().contains('mix') ||
                    d.toLowerCase().contains('output'),
              );
            } catch (_) {
              _selectedSpeakerDevice ??= _availableAudioDevices.first;
            }
          }
        }

        await recorder.startRecording(
          format: _selectedFormat,
          x: x,
          y: y,
          width: width,
          height: height,
          speakerEnabled: _speakerEnabled,
          micEnabled: _micEnabled,
          speakerDevice: _selectedSpeakerDevice,
          micDevice: _selectedMicDevice,
          speakerVolume: _speakerVolume,
          micVolume: _micVolume,
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

  void startRegionSelection([Rect? initialRect]) {
    AppLogger.info(
      'Entering region selection mode with initial rect: $initialRect',
    );
    onSelectRegion(initialRect);
  }

  void togglePause() {
    if (_isRecording) {
      _isPaused = !_isPaused;
      notifyListeners();
      AppLogger.info('Recording paused state changed to: $_isPaused');
      // Note: True FFmpeg pausing requires suspending the process or splitting the video.
      // Currently, this just pauses the timer UI.
    }
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
