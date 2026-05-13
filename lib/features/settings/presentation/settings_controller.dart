import 'dart:io';
import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  String _ffmpegStatus = 'Checking...';
  String? _ffmpegVersion;
  bool _isFfmpegAvailable = false;

  String get ffmpegStatus => _ffmpegStatus;
  String? get ffmpegVersion => _ffmpegVersion;
  bool get isFfmpegAvailable => _isFfmpegAvailable;

  Future<void> checkFfmpeg() async {
    _ffmpegStatus = 'Checking...';
    notifyListeners();

    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        _isFfmpegAvailable = true;
        _ffmpegStatus = 'Available';
        // Extract version from first line (e.g., ffmpeg version 4.4.1...)
        _ffmpegVersion = result.stdout.toString().split('\n').first;
      } else {
        _isFfmpegAvailable = false;
        _ffmpegStatus = 'Not found or error';
      }
    } catch (e) {
      _isFfmpegAvailable = false;
      _ffmpegStatus = 'Not found in system PATH';
    }
    notifyListeners();
  }
}
