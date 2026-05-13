import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class GalleryController extends ChangeNotifier {
  final String outputDir;
  List<FileSystemEntity> _files = [];

  GalleryController({required this.outputDir});

  List<FileSystemEntity> get files => _files;

  Future<void> loadFiles() async {
    try {
      final dir = Directory(outputDir);
      if (await dir.exists()) {
        final fileList = dir.listSync().where((file) {
          if (file is! File) return false;
          final ext = p.extension(file.path).toLowerCase();
          return ext == '.mkv' ||
              ext == '.mp4' ||
              ext == '.avi' ||
              ext == '.gif';
        }).toList();

        // Sort by modified date descending
        fileList.sort((a, b) {
          final statA = a.statSync();
          final statB = b.statSync();
          return statB.modified.compareTo(statA.modified);
        });

        _files = fileList;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load files: $e');
    }
  }

  Future<void> renameFile(FileSystemEntity file, String newName) async {
    final ext = p.extension(file.path);
    final newPath = p.join(p.dirname(file.path), '$newName$ext');
    await file.rename(newPath);
    await loadFiles();
  }

  Future<void> deleteFile(FileSystemEntity file) async {
    await file.delete();
    await loadFiles();
  }
}
