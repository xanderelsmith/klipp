import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/logger.dart';

class GalleryController extends ChangeNotifier {
  final String outputDir;
  List<FileSystemEntity> _files = [];
  StreamSubscription? _directorySubscription;

  GalleryController({required this.outputDir}) {
    _initWatcher();
    loadFiles(); // Initial load
  }

  List<FileSystemEntity> get files => _files;

  void _initWatcher() {
    final dir = Directory(outputDir);
    _directorySubscription = dir.watch().listen((event) {
      AppLogger.info('Directory event: ${event.type} on ${event.path}');
      loadFiles();
    });
  }

  Future<void> loadFiles() async {
    try {
      final dir = Directory(outputDir);
      if (await dir.exists()) {
        final stream = dir.list();
        final List<FileSystemEntity> fileList = [];

        await for (final entity in stream) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            if (['.mkv', '.mp4', '.avi', '.gif'].contains(ext)) {
              // Verify existence before adding
              if (await entity.exists()) {
                fileList.add(entity);
              }
            }
          }
        }

        // Sort by modified date descending (safely)
        final List<MapEntry<FileSystemEntity, DateTime>> datedFiles = [];
        for (final file in fileList) {
          try {
            final stat = await file.stat();
            datedFiles.add(MapEntry(file, stat.modified));
          } catch (_) {
            // Skip if file disappeared during processing
          }
        }

        datedFiles.sort((a, b) => b.value.compareTo(a.value));
        _files = datedFiles.map((e) => e.key).toList();
        
        AppLogger.info('Refreshed gallery: ${_files.length} files');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load gallery files', e, stackTrace);
    }
  }

  Future<void> renameFile(FileSystemEntity file, String newName) async {
    try {
      final ext = p.extension(file.path);
      final newPath = p.join(p.dirname(file.path), '$newName$ext');
      if (await file.exists()) {
        await file.rename(newPath);
        AppLogger.info('Renamed file: ${file.path} -> $newPath');
        // Watcher will trigger reload
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to rename file', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFile(FileSystemEntity file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Deleted file: ${file.path}');
        // Watcher will trigger reload
      }
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 32) {
        AppLogger.warning('File in use: ${file.path}');
        throw 'Cannot delete: File is currently in use by another process (e.g., FFmpeg or a video player).';
      }
      AppLogger.error('Failed to delete file', e);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _directorySubscription?.cancel();
    super.dispose();
  }
}
