import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';

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
      AppLogger.info('Checking FFmpeg availability...');
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        _isFfmpegAvailable = true;
        _ffmpegStatus = 'Available';
        _ffmpegVersion = result.stdout.toString().split('\n').first;
        AppLogger.info('FFmpeg found: $_ffmpegVersion');
      } else {
        _isFfmpegAvailable = false;
        _ffmpegStatus = 'Not found or error';
        AppLogger.warning('FFmpeg found but returned exit code ${result.exitCode}');
      }
    } catch (e, stackTrace) {
      _isFfmpegAvailable = false;
      _ffmpegStatus = 'Not found in system PATH';
      AppLogger.error('FFmpeg not found in system PATH', e, stackTrace);
    }
    notifyListeners();
  }
}
