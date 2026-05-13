import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DesktopScreenRecorder {
  Process? _recordingProcess;
  String? _currentOutputPath;

  Future<String?> getPlatformVersion() async {
    return "Windows (Custom FFMpeg implementation)";
  }

  /// Starts recording the screen and returns the path to the output file.
  Future<String?> startRecording({
    String? fileName,
    String format = 'mkv',
    int? x,
    int? y,
    int? width,
    int? height,
  }) async {
    if (_recordingProcess != null) {
      throw Exception('Already recording');
    }

    final directory = await getApplicationDocumentsDirectory();
    final klippDir = Directory('${directory.path}\\klippvideos');
    if (!await klippDir.exists()) {
      await klippDir.create(recursive: true);
    }

    final name = fileName ??
        'recording_${DateTime.now().millisecondsSinceEpoch}.$format';
    _currentOutputPath = '${klippDir.path}\\$name';

    try {
      final List<String> args = [
        '-f',
        'gdigrab',
        '-framerate',
        '30',
      ];

      if (x != null && y != null && width != null && height != null) {
        args.addAll([
          '-offset_x',
          '$x',
          '-offset_y',
          '$y',
          '-video_size',
          '${width}x$height',
        ]);
      }

      args.addAll([
        '-i',
        'desktop',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-y',
        _currentOutputPath!
      ]);

      _recordingProcess = await Process.start('ffmpeg', args);

      // Log output for debugging
      _recordingProcess!.stdout
          .transform(SystemEncoding().decoder)
          .listen((data) {
        if (kDebugMode) {
          print('FFMPEG STDOUT: $data');
        }
      });
      _recordingProcess!.stderr
          .transform(SystemEncoding().decoder)
          .listen((data) {
        print('FFMPEG STDERR: $data');
      });

      // Auto-clear process if it exits unexpectedly
      _recordingProcess!.exitCode.then((code) {
        print('FFMPEG EXITED WITH CODE $code');
        _recordingProcess = null;
      });

      return _currentOutputPath;
    } catch (e) {
      _recordingProcess = null;
      throw Exception(
          'Failed to start recording. Please ensure FFmpeg is installed and in your system PATH: $e');
    }
  }

  /// Stops the recording and returns the final file path.
  Future<String?> stopRecording() async {
    if (_recordingProcess == null) {
      return null;
    }

    try {
      _recordingProcess!.stdin.writeln('q');
    } catch (_) {}

    final timer = Timer(const Duration(seconds: 3), () {
      _recordingProcess?.kill();
    });

    await _recordingProcess!.exitCode;
    timer.cancel();
    _recordingProcess = null;

    final path = _currentOutputPath;
    _currentOutputPath = null;
    return path;
  }

  /// Converts a video file to another format, optionally compressing it.
  Future<void> convertVideo({
    required String inputPath,
    required String outputPath,
    bool compress = false,
  }) async {
    List<String> args = ['-i', inputPath];

    if (outputPath.toLowerCase().endsWith('.gif')) {
      args.addAll([
        '-vf',
        'fps=15,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse'
      ]);
    } else if (compress) {
      args.addAll(['-c:v', 'libx264', '-crf', '28', '-preset', 'faster']);
    }

    args.addAll(['-y', outputPath]);

    final process = await Process.start('ffmpeg', args);
    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      print('CONVERSION STDERR: $data');
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('FFmpeg conversion failed with exit code $exitCode');
    }
  }
}
