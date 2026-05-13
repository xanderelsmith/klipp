import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_screen_recorder/desktop_screen_recorder.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/logger.dart';

class ConverterController extends ChangeNotifier {
  final DesktopScreenRecorder recorder;
  final String outputDir;
  final VoidCallback onConversionCompleted;

  String? _inputFile;
  String _targetFormat = 'mp4';
  bool _compress = false;
  bool _exportToSameDir = false;
  bool _isConverting = false;
  bool _isDragging = false;

  ConverterController({
    required this.recorder,
    required this.outputDir,
    required this.onConversionCompleted,
  });

  String? get inputFile => _inputFile;
  String get targetFormat => _targetFormat;
  bool get compress => _compress;
  bool get exportToSameDir => _exportToSameDir;
  bool get isConverting => _isConverting;
  bool get isDragging => _isDragging;

  set inputFile(String? file) {
    _inputFile = file;
    AppLogger.info('Input file selected for conversion: $file');
    notifyListeners();
  }

  set targetFormat(String format) {
    _targetFormat = format;
    AppLogger.info('Target format changed to: $format');
    notifyListeners();
  }

  set compress(bool value) {
    _compress = value;
    notifyListeners();
  }

  set exportToSameDir(bool value) {
    _exportToSameDir = value;
    notifyListeners();
  }

  set isDragging(bool value) {
    _isDragging = value;
    notifyListeners();
  }

  Future<void> convert() async {
    if (_inputFile == null) return;

    _isConverting = true;
    notifyListeners();

    try {
      final baseName = p.basenameWithoutExtension(_inputFile!);
      String outputDirPath;

      if (_exportToSameDir) {
        outputDirPath = p.dirname(_inputFile!);
      } else {
        final dir = Directory(outputDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        outputDirPath = dir.path;
      }

      final outPath = p.join(
        outputDirPath,
        '${baseName}_converted_${DateTime.now().millisecondsSinceEpoch}.$_targetFormat',
      );

      AppLogger.info(
        'Starting conversion: Input=$_inputFile, Output=$outPath, Compress=$_compress',
      );

      await recorder.convertVideo(
        inputPath: _inputFile!,
        outputPath: outPath,
        compress: _compress,
      );

      AppLogger.info('Conversion completed successfully');
      onConversionCompleted();
    } catch (e, stackTrace) {
      AppLogger.error('Conversion failed', e, stackTrace);
      rethrow;
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }
}
